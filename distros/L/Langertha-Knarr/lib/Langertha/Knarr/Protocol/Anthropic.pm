package Langertha::Knarr::Protocol::Anthropic;
# ABSTRACT: Anthropic-compatible wire protocol (/v1/messages) for Knarr

our $VERSION = '1.001';
use Moose;
use JSON::MaybeXS;
use Time::HiRes qw( time );
use Langertha::Knarr::Request;

with 'Langertha::Knarr::Protocol';

# --- Streaming model ---
# Anthropic Messages SSE — multiple named events per stream:
#   event: message_start         data: {"type":"message_start","message":{...}}
#   event: content_block_start   data: {"type":"content_block_start","index":0,
#                                       "content_block":{"type":"text","text":""}}
#   event: content_block_delta   data: {"type":"content_block_delta","index":0,
#                                       "delta":{"type":"text_delta","text":"Hi"}}
#   event: content_block_stop    data: {"type":"content_block_stop","index":0}
#   event: message_delta         data: {"type":"message_delta",
#                                       "delta":{"stop_reason":"end_turn"},
#                                       "usage":{"output_tokens":N}}
#   event: message_stop          data: {"type":"message_stop"}
# So a single delta from the handler MUST translate into a content_block_delta.
# We need the protocol to also be able to emit synthesized "start" and "stop"
# frames around the stream — the runtime will call format_stream_open / _close.
# ----------------------

has steerboard => ( is => 'ro', weak_ref => 1 );
has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );

sub protocol_name { 'anthropic' }

sub protocol_routes {
  return [
    { method => 'POST', path => '/v1/messages', action => 'chat' },
  ];
}

sub _msg_id { 'msg_' . int( time() * 1000 ) }

sub parse_chat_request {
  my ($self, $http_req, $body_ref) = @_;
  my $data = $self->_json->decode( $$body_ref || '{}' );
  # Anthropic puts system prompt outside messages.
  # system can be a string or an array of content blocks [{type:"text",text:"..."},...]
  my $system_raw = $data->{system};
  my $system_str;
  if (ref $system_raw eq 'ARRAY') {
    $system_str = join("\n", map { $_->{text} // '' } @$system_raw);
  } elsif (defined $system_raw) {
    $system_str = $system_raw;
  }
  my @msgs;
  push @msgs, { role => 'system', content => $system_str } if defined $system_str;
  push @msgs, @{ $data->{messages} || [] };
  # Capture auth headers for passthrough
  my %fwd;
  for my $h (qw( x-api-key anthropic-version authorization )) {
    my $v = scalar $http_req->header($h);
    $fwd{$h} = $v if defined $v && length $v;
  }
  return Langertha::Knarr::Request->new(
    protocol    => 'anthropic',
    raw         => $data,
    model       => $data->{model},
    messages    => \@msgs,
    stream      => $data->{stream} ? 1 : 0,
    temperature => $data->{temperature},
    max_tokens  => $data->{max_tokens},
    system      => $system_str,
    tools       => $data->{tools},
    extra       => { forward_headers => \%fwd },
  );
}

sub format_chat_response {
  my ($self, $response, $request) = @_;
  my $content = ref $response eq 'HASH' ? $response->{content} : "$response";
  my $model   = ( ref $response eq 'HASH' && $response->{model} ) || $request->model || 'steerboard';
  my $payload = {
    id      => _msg_id(),
    type    => 'message',
    role    => 'assistant',
    model   => $model,
    content => [ { type => 'text', text => $content } ],
    stop_reason   => 'end_turn',
    stop_sequence => undef,
    usage   => { input_tokens => 0, output_tokens => 0 },
  };
  return ( 200, { 'Content-Type' => 'application/json' }, $self->_json->encode($payload) );
}

# Anthropic streaming uses named SSE events. We render full event blocks.
sub _sse_event {
  my ($self, $event, $data) = @_;
  return "event: $event\ndata: " . $self->_json->encode($data) . "\n\n";
}

sub format_stream_open {
  my ($self, $request) = @_;
  my $id = _msg_id();
  my $model = $request->model // 'steerboard';
  return join( '',
    $self->_sse_event( message_start => {
      type    => 'message_start',
      message => {
        id => $id, type => 'message', role => 'assistant',
        content => [], model => $model,
        stop_reason => undef, stop_sequence => undef,
        usage => { input_tokens => 0, output_tokens => 0 },
      },
    }),
    $self->_sse_event( content_block_start => {
      type => 'content_block_start',
      index => 0,
      content_block => { type => 'text', text => '' },
    }),
  );
}

sub format_stream_chunk {
  my ($self, $delta_text, $request) = @_;
  return $self->_sse_event( content_block_delta => {
    type  => 'content_block_delta',
    index => 0,
    delta => { type => 'text_delta', text => $delta_text },
  });
}

sub format_stream_close {
  my ($self, $request) = @_;
  return join( '',
    $self->_sse_event( content_block_stop => { type => 'content_block_stop', index => 0 } ),
    $self->_sse_event( message_delta => {
      type => 'message_delta',
      delta => { stop_reason => 'end_turn', stop_sequence => undef },
      usage => { output_tokens => 0 },
    }),
    $self->_sse_event( message_stop => { type => 'message_stop' } ),
  );
}

sub format_stream_done { '' }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::Anthropic - Anthropic-compatible wire protocol (/v1/messages) for Knarr

=head1 VERSION

version 1.001

=head1 DESCRIPTION

Implements the Anthropic Messages wire format on top of
L<Langertha::Knarr::Protocol>. Loaded by default.

=over

=item * C<POST /v1/messages> — sync and named-event SSE streaming

=back

Streaming emits the full event sequence the Anthropic SDK expects:
C<message_start>, C<content_block_start>, C<content_block_delta>×N,
C<content_block_stop>, C<message_delta>, C<message_stop>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

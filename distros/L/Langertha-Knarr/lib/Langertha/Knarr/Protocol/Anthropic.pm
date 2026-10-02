package Langertha::Knarr::Protocol::Anthropic;
# ABSTRACT: Anthropic-compatible wire protocol (/v1/messages) for Knarr

our $VERSION = '1.102';
use Moose;
use JSON::MaybeXS;
use Time::HiRes qw( time );
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Image;
use Langertha::Knarr::Reasoning;

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

has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );
# Tool arguments become a JSON string inside an event that _json encodes to
# UTF-8, so they are encoded to characters here, not to bytes.
has _args_json => ( is => 'ro', default => sub { JSON::MaybeXS->new( canonical => 1 ) } );

has reasoning => (
  is      => 'ro',
  isa     => 'Langertha::Knarr::Reasoning',
  lazy    => 1,
  builder => '_build_reasoning',
);

sub _build_reasoning { Langertha::Knarr::Reasoning->new }


sub protocol_name { 'anthropic' }

sub protocol_routes {
  return [
    { method => 'POST', path => '/v1/messages', action => 'chat' },
  ];
}

# Provider manifest (k14): anthropic-compat, not anthropic. parse_chat_request
# below carries tools and tool_choice but not output_config.format, so a
# client must do structured output the shim way (synthetic tool + forced
# tool_choice). thinking and output_config.effort arrive as reasoning_effort
# (k13); cache_control and disable_parallel_tool_use are not forwarded.
sub manifest_endpoint {
  return {
    dialect      => 'anthropic-compat',
    path         => '',
    capabilities => [qw(
      chat streaming system_prompt
      tools_native tools_hermes
      tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
      temperature response_size reasoning_effort
      image_input
    )],
    # image blocks become Langertha::Content::Image objects (k33); an older
    # core gets them as sent, readable only by Anthropic-shape engines.
    image_content_formats => Langertha::Knarr::Image::content_formats(qw( anthropic )),
  };
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
  push @msgs, @{ Langertha::Knarr::Image::anthropic_messages( $data->{messages} || [] ) };
  # Capture auth headers for passthrough, one pair per line (k60)
  my $fwd = $self->_forward_headers( $http_req, qw( x-api-key anthropic-version authorization ) );
  return Langertha::Knarr::Request->new(
    protocol    => 'anthropic',
    raw         => $data,
    model       => $data->{model},
    messages    => \@msgs,
    stream      => $data->{stream} ? 1 : 0,
    temperature => $data->{temperature},
    max_tokens  => $data->{max_tokens},
    reasoning_effort => scalar $self->reasoning->from_anthropic($data),
    system      => $system_str,
    tools       => $data->{tools},
    tool_choice => $data->{tool_choice},
    extra       => { forward_headers => $fwd },
  );
}

# Anthropic's stop_reason is a closed enum; the engine Response carries the
# backend's own finish_reason (OpenAI tool_calls/length/stop/content_filter,
# Gemini STOP/MAX_TOKENS, ...). Values already in Anthropic vocabulary pass
# through; a value with no Anthropic counterpart falls back like an absent one.
my %STOP_REASON = (
  ( map { $_ => $_ } qw( end_turn max_tokens stop_sequence tool_use pause_turn refusal ) ),
  tool_calls     => 'tool_use',
  function_call  => 'tool_use',
  length         => 'max_tokens',
  content_filter => 'refusal',
);

sub _stop_reason {
  my ( $finish_reason, $has_tool_calls ) = @_;
  my $fallback = $has_tool_calls ? 'tool_use' : 'end_turn';
  return $fallback unless defined $finish_reason;
  my $key = lc $finish_reason;
  return $fallback if $key eq 'stop';
  return $STOP_REASON{$key} // $fallback;
}

sub format_chat_response {
  my ($self, $response, $request) = @_;
  my $r = Langertha::Knarr::Response->coerce($response);
  my @blocks;
  push @blocks, { type => 'text', text => $r->content } if length $r->content;
  push @blocks, map { $_->to_anthropic_block } @{ $r->tool_calls };
  push @blocks, { type => 'text', text => '' } unless @blocks;
  my $stop_reason = _stop_reason( $r->finish_reason, $r->has_tool_calls );
  my $usage = $r->usage && $r->usage->can('to_anthropic_format')
    ? $r->usage->to_anthropic_format
    : { input_tokens => 0, output_tokens => 0 };
  my $payload = {
    id      => _msg_id(),
    type    => 'message',
    role    => 'assistant',
    model   => $r->model // $request->model // 'unknown',
    content => \@blocks,
    stop_reason   => $stop_reason,
    stop_sequence => undef,
    usage   => $usage,
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
  my $model = $request->model // 'unknown';
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

# The routed stream carries the backend's tool calls complete, not as they
# were fragmented upstream, so each call closes the stream as its own
# tool_use block: content_block_start with an empty input, one
# input_json_delta holding the full arguments, content_block_stop (k19).
# message_delta carries the stream's usage, cumulative as Anthropic's own
# does -- input_tokens included, since message_start went out before the
# backend reported any.
sub format_stream_close {
  my ($self, $request, $finish_reason, $tool_calls, $usage) = @_;
  my @calls = @{ $tool_calls // [] };
  my $stop_reason = _stop_reason( $finish_reason, scalar @calls );
  my @tool_events;
  my $index = 0;
  for my $tc (@calls) {
    $index++;
    my $block = $tc->to_anthropic_block( fallback_id => "toolu_knarr_$index" );
    push @tool_events,
      $self->_sse_event( content_block_start => {
        type  => 'content_block_start',
        index => $index,
        content_block => { type => 'tool_use', id => $block->{id}, name => $block->{name}, input => {} },
      }),
      $self->_sse_event( content_block_delta => {
        type  => 'content_block_delta',
        index => $index,
        delta => { type => 'input_json_delta', partial_json => $self->_args_json->encode( $block->{input} ) },
      }),
      $self->_sse_event( content_block_stop => { type => 'content_block_stop', index => $index } );
  }
  return join( '',
    $self->_sse_event( content_block_stop => { type => 'content_block_stop', index => 0 } ),
    @tool_events,
    $self->_sse_event( message_delta => {
      type => 'message_delta',
      delta => { stop_reason => $stop_reason, stop_sequence => undef },
      usage => ( $usage && $usage->can('to_anthropic_format')
        ? $usage->to_anthropic_format : { output_tokens => 0 } ),
    }),
    $self->_sse_event( message_stop => { type => 'message_stop' } ),
  );
}

sub format_stream_done { '' }

# Anthropic's error types by HTTP status; anything else is an api_error.
my %ERROR_TYPE = (
  400 => 'invalid_request_error', 401 => 'authentication_error',
  403 => 'permission_error',      404 => 'not_found_error',
  413 => 'request_too_large',     429 => 'rate_limit_error',
  504 => 'timeout_error',         529 => 'overloaded_error',
);

sub _error_payload {
  my ($status, $message) = @_;
  return { type => 'error',
    error => { type => $ERROR_TYPE{$status} // 'api_error', message => "$message" } };
}

sub format_error_response {
  my ($self, $status, $message) = @_;
  return ( $status, { 'Content-Type' => 'application/json' },
    $self->_json->encode( _error_payload( $status, $message ) ) );
}

sub format_stream_error {
  my ($self, $status, $message) = @_;
  return $self->_sse_event( error => _error_payload( $status, $message ) );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::Anthropic - Anthropic-compatible wire protocol (/v1/messages) for Knarr

=head1 VERSION

version 1.102

=head1 DESCRIPTION

Implements the Anthropic Messages wire format on top of
L<Langertha::Knarr::Protocol>. Loaded by default.

=over

=item * C<POST /v1/messages> — sync and named-event SSE streaming

=back

Streaming emits the full event sequence the Anthropic SDK expects:
C<message_start>, C<content_block_start>, C<content_block_delta>×N,
C<content_block_stop>, C<message_delta>, C<message_stop>.

=head2 reasoning

The L<Langertha::Knarr::Reasoning> that maps the body's C<thinking> (and an
explicit C<output_config.effort>) onto the request's C<reasoning_effort>.
Pass your own to override its default level or budget anchors.

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

package Langertha::Knarr::Protocol::AGUI;
# ABSTRACT: AG-UI (Agent-UI) event protocol for Knarr

our $VERSION = '1.001';
use Moose;
use JSON::MaybeXS;
use Data::UUID;
use Time::HiRes qw( time );
use Langertha::Knarr::Request;

with 'Langertha::Knarr::Protocol';

# --- AG-UI overview ---
# CopilotKit-driven event protocol meant for agent <-> UI streaming.
# Transport-agnostic; SSE is the canonical wire form.
# Endpoint convention: POST /awp (Agent Wire Protocol) — body is the run input,
# response is an SSE stream of typed events.
#
# Event types (subset, all framed as SSE "data: { ... }" with "type" field):
#   RUN_STARTED            { type, threadId, runId }
#   TEXT_MESSAGE_START     { type, messageId, role:"assistant" }
#   TEXT_MESSAGE_CONTENT   { type, messageId, delta:"..." }
#   TEXT_MESSAGE_END       { type, messageId }
#   TOOL_CALL_START        { type, toolCallId, toolCallName, parentMessageId }
#   TOOL_CALL_ARGS         { type, toolCallId, delta:"..." }
#   TOOL_CALL_END          { type, toolCallId }
#   STATE_SNAPSHOT / STATE_DELTA / MESSAGES_SNAPSHOT
#   RUN_FINISHED           { type, threadId, runId }
#   RUN_ERROR              { type, message, code }
# ---------------------------------------------------------------------------

has steerboard => ( is => 'ro', weak_ref => 1 );
has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );
has _uuid => ( is => 'ro', default => sub { Data::UUID->new } );

sub protocol_name { 'agui' }

sub protocol_routes {
  return [
    { method => 'POST', path => '/awp', action => 'chat' },
  ];
}

sub parse_chat_request {
  my ($self, $http_req, $body_ref) = @_;
  my $data = $self->_json->decode( $$body_ref || '{}' );
  my @msgs;
  for my $m ( @{ $data->{messages} || [] } ) {
    push @msgs, { role => $m->{role} // 'user', content => $m->{content} // '' };
  }
  return Langertha::Knarr::Request->new(
    protocol => 'agui',
    raw      => $data,
    model    => $data->{model},
    messages => \@msgs,
    stream   => 1,  # AG-UI is always streaming
    session_id => $data->{threadId},
    extra => {
      thread_id  => $data->{threadId} // $self->_uuid->create_str,
      run_id     => $data->{runId}    // $self->_uuid->create_str,
      message_id => $self->_uuid->create_str,
    },
  );
}

sub format_chat_response {
  my ($self, $response, $request) = @_;
  # AG-UI doesn't really have a "non-stream" mode — emit a synthetic single
  # SSE-encoded sequence as the body for sync clients.
  my $content = ref $response eq 'HASH' ? $response->{content} : "$response";
  my $body = join( '',
    $self->format_stream_open($request),
    $self->format_stream_chunk($content, $request),
    $self->format_stream_close($request),
  );
  return ( 200, { 'Content-Type' => 'text/event-stream' }, $body );
}

sub _sse {
  my ($self, $data) = @_;
  return "data: " . $self->_json->encode($data) . "\n\n";
}

sub format_stream_open {
  my ($self, $request) = @_;
  return join( '',
    $self->_sse({
      type => 'RUN_STARTED',
      threadId => $request->extra->{thread_id},
      runId    => $request->extra->{run_id},
    }),
    $self->_sse({
      type => 'TEXT_MESSAGE_START',
      messageId => $request->extra->{message_id},
      role => 'assistant',
    }),
  );
}

sub format_stream_chunk {
  my ($self, $delta_text, $request) = @_;
  return $self->_sse({
    type => 'TEXT_MESSAGE_CONTENT',
    messageId => $request->extra->{message_id},
    delta => $delta_text,
  });
}

sub format_stream_close {
  my ($self, $request) = @_;
  return join( '',
    $self->_sse({
      type => 'TEXT_MESSAGE_END',
      messageId => $request->extra->{message_id},
    }),
    $self->_sse({
      type => 'RUN_FINISHED',
      threadId => $request->extra->{thread_id},
      runId    => $request->extra->{run_id},
    }),
  );
}

sub format_stream_done { '' }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::AGUI - AG-UI (Agent-UI) event protocol for Knarr

=head1 VERSION

version 1.001

=head1 DESCRIPTION

Implements the CopilotKit AG-UI agent-to-UI event protocol on top of
L<Langertha::Knarr::Protocol>. Loaded by default.

=over

=item * C<POST /awp> — Agent Wire Protocol endpoint, always streaming

=back

Streaming emits the typed AG-UI event sequence:
C<RUN_STARTED>, C<TEXT_MESSAGE_START>, C<TEXT_MESSAGE_CONTENT>×N,
C<TEXT_MESSAGE_END>, C<RUN_FINISHED>. Sync mode synthesizes the same
sequence into a single response body for non-streaming clients.

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

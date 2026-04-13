package Langertha::Knarr::Protocol;
# ABSTRACT: Role for Knarr wire protocols (OpenAI, Anthropic, Ollama, A2A, ACP, AG-UI)
our $VERSION = '1.001';
use Moose::Role;


# Identifier (e.g. 'openai', 'anthropic', 'ollama').
requires 'protocol_name';

# Returns arrayref of route specs:
#   [ { method => 'POST', path => '/v1/chat/completions', action => 'chat' }, ... ]
requires 'protocol_routes';

# parse_chat_request($http_req, $body_ref) -> Langertha::Knarr::Request
requires 'parse_chat_request';

# format_chat_response($response, $request) -> ($status, \%headers, $body)
requires 'format_chat_response';

# format_stream_chunk($chunk, $request) -> string (raw bytes for the wire)
# Default: SSE-style "data: {...}\n\n" — protocols may override (Ollama uses NDJSON).
sub format_stream_chunk {
  my ($self, $chunk_json) = @_;
  return "data: $chunk_json\n\n";
}

sub format_stream_done {
  my ($self) = @_;
  return "data: [DONE]\n\n";
}

# Optional lifecycle hooks for protocols that need to frame the stream
# (Anthropic message_start/stop, A2A status events, ACP run.created, AGUI RUN_STARTED).
# Default: empty — protocols like OpenAI / Ollama don't need them.
sub format_stream_open  { '' }
sub format_stream_close { '' }

# Content-Type for streaming responses. Default is SSE; Ollama overrides.
sub stream_content_type { 'text/event-stream' }

# format_models_response(\@models) -> ($status, \%headers, $body)
sub format_models_response {
  my ($self, $models) = @_;
  return ( 200, { 'Content-Type' => 'application/json' }, '{"data":[]}' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol - Role for Knarr wire protocols (OpenAI, Anthropic, Ollama, A2A, ACP, AG-UI)

=head1 VERSION

version 1.001

=head1 DESCRIPTION

The role every Knarr wire protocol must consume. A protocol declares
its routes, parses incoming HTTP bodies into a normalized
L<Langertha::Knarr::Request>, and formats outgoing
L<Langertha::Knarr::Stream> chunks back into the protocol-native wire
format. The Knarr core dispatches each request to the right handler
via the matched protocol's parser/formatter.

Knarr ships with six concrete protocols, all loaded by default:

=over

=item * L<Langertha::Knarr::Protocol::OpenAI> — C</v1/chat/completions>, SSE

=item * L<Langertha::Knarr::Protocol::Anthropic> — C</v1/messages>, named SSE events

=item * L<Langertha::Knarr::Protocol::Ollama> — C</api/chat>, NDJSON streaming

=item * L<Langertha::Knarr::Protocol::A2A> — Google Agent2Agent JSON-RPC

=item * L<Langertha::Knarr::Protocol::ACP> — IBM/BeeAI Agent Communication Protocol

=item * L<Langertha::Knarr::Protocol::AGUI> — CopilotKit AG-UI event protocol

=back

=head2 protocol_name

Required. Returns a short string identifier (e.g. C<'openai'>).

=head2 protocol_routes

Required. Returns an arrayref of route specs of the form
C<< { method => 'POST', path => '/v1/chat/completions', action => 'chat' } >>.
Action names map to C<_action_*> methods on the Knarr core.

=head2 parse_chat_request

    my $req = $proto->parse_chat_request($http_request, \$body);

Required. Returns a L<Langertha::Knarr::Request>.

=head2 format_chat_response

    my ($status, \%headers, $body) = $proto->format_chat_response($response, $request);

Required. Returns the HTTP response triple for sync mode.

=head2 format_stream_open / format_stream_chunk / format_stream_close / format_stream_done

Lifecycle hooks for streaming responses. Defaults are no-ops where the
protocol doesn't need framing — Anthropic/A2A/ACP/AG-UI override these
to emit their named events around the chunk stream.

=head2 stream_content_type

Returns the HTTP C<Content-Type> for streaming responses. Default
C<text/event-stream>; Ollama overrides to C<application/x-ndjson>.

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

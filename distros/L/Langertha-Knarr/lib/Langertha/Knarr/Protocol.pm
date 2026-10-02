package Langertha::Knarr::Protocol;
# ABSTRACT: Role for Knarr wire protocols (OpenAI, Anthropic, Ollama, A2A, ACP, AG-UI)
our $VERSION = '1.102';
use Moose::Role;
use JSON::MaybeXS ();
use Scalar::Util ();


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

# An error answer in the protocol's own shape; default is the OpenAI wire's.
sub format_error_response {
  my ($self, $status, $message) = @_;
  return ( $status, { 'Content-Type' => 'application/json' },
    JSON::MaybeXS->new( utf8 => 1, canonical => 1 )->encode({ error => { message => "$message" } }) );
}

# The frame that marks a stream as failed once its headers are out; ''
# when the protocol has none.
sub format_stream_error { '' }

# Content-Type for streaming responses. Default is SSE; Ollama overrides.
sub stream_content_type { 'text/event-stream' }

# Manifest publication (k14): undef = not in the provider manifest.
sub manifest_endpoint { undef }

# format_models_response(\@models) -> ($status, \%headers, $body)
sub format_models_response {
  my ($self, $models) = @_;
  return ( 200, { 'Content-Type' => 'application/json' }, '{"data":[]}' );
}

# The client's headers of the given names as [ name, value ] pairs for a
# Request's forward_headers: one pair per line the client sent, repeats in
# their order, read with a list-context ->header (k60). A request object
# that has no ->header gives none.
sub _forward_headers {
  my ($self, $http_req, @names) = @_;
  return [] unless Scalar::Util::blessed($http_req) && $http_req->can('header');
  my @pairs;
  for my $name (@names) {
    push @pairs, map { [ $name, $_ ] } grep { defined && length } $http_req->header($name);
  }
  return \@pairs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol - Role for Knarr wire protocols (OpenAI, Anthropic, Ollama, A2A, ACP, AG-UI)

=head1 VERSION

version 1.102

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

C<format_stream_close> and C<format_stream_done> are called as
C<($request, $finish_reason, $tool_calls, $usage)>: the second argument is the
backend's terminal finish reason from L<Langertha::Knarr::Stream/finish_reason>,
verbatim and possibly C<undef> (always C<undef> after a stream error).
A protocol maps it into its own vocabulary; Anthropic puts it on
C<message_delta>, OpenAI on a terminal chunk, Ollama on C<done_reason>.

The third argument is an ArrayRef of complete L<Langertha::ToolCall>
objects from L<Langertha::Knarr::Stream/tool_calls>, empty when the
backend emitted none (and absent after a stream error). A protocol that
can carry tool calls emits them before its terminal frames: Anthropic
as C<tool_use> content blocks, OpenAI as one C<delta.tool_calls> chunk,
Ollama as C<message.tool_calls> on the done line.
The fourth argument is the stream's token usage from
L<Langertha::Knarr::Stream/usage>, a L<Langertha::Usage>, or C<undef> when
the backend reported none (and after a stream error). Anthropic reports it
on C<message_delta>, Ollama as C<prompt_eval_count> / C<eval_count> on the
done line, OpenAI in a C<usage> chunk after the terminal one when the client
asked for it with C<stream_options.include_usage>.

=head2 format_error_response

    my ($status, \%headers, $body) = $proto->format_error_response( 504, 'upstream timed out' );

An error answer in this protocol's shape. Default: the OpenAI wire's
C<{"error":{"message":...}}>; Anthropic answers
C<{"type":"error","error":{"type":...,"message":...}}>, Ollama a plain
C<{"error":"..."}>.

=head2 format_stream_error

    my $bytes = $proto->format_stream_error( 504, 'upstream timed out' );

The frame that tells a client its stream failed after the response
headers went out, or C<''> (the default) when the protocol has none.
OpenAI sends C<data: {"error":{...}}>, Anthropic an C<event: error>,
Ollama an C<{"error":"..."}> line. The raw passthrough writes it before
closing a stream the upstream stopped feeding, and so does a routed stream
whose handler failed with an upstream timeout.

=head2 stream_content_type

Returns the HTTP C<Content-Type> for streaming responses. Default
C<text/event-stream>; Ollama overrides to C<application/x-ndjson>.

=head2 manifest_endpoint

    my $spec = $proto->manifest_endpoint;
    # { dialect => 'openai-chat', path => '/v1', capabilities => [ ... ],
    #   image_content_formats => [ 'openai', 'gemini' ] }

How this protocol appears in the provider manifest
(C</.well-known/langertha.json>, see L<Langertha::Knarr/MANIFEST>), or
C<undef> (the default) when it has no manifest dialect and is not
published. C<dialect> is a Langertha manifest dialect, C<path> is appended
to the public base URL to form the endpoint's C<base_url>, and
C<capabilities> lists the capability flags this protocol's
L</parse_chat_request> actually carries to the engine. A published model
claims a capability on this endpoint only when its engine has it B<and>
it is in this list.

C<image_input> additionally needs C<image_content_formats>: the engine
C<content_format>s (C<openai>, C<anthropic>, C<gemini>, C<ollama>, ...)
that read this protocol's image parts; a model is published with
C<image_input> on this endpoint only when its engine's content format is
listed. The OpenAI, Anthropic and Ollama protocols translate their image
parts into L<Langertha::Content::Image> objects and list every format
(L<Langertha::Knarr::Image>); on a core too old for that the parts pass
through untranslated and only the formats that read the protocol's own
shape are listed.

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

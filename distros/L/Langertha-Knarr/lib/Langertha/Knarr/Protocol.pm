package Langertha::Knarr::Protocol;
# ABSTRACT: Role for Knarr wire protocols (OpenAI, Anthropic, Ollama, A2A, ACP, AG-UI)
our $VERSION = '1.103';
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
sub error_uses_body { 0 }

# The reason a request body cannot be a chat request, or nothing: it is not
# JSON, or JSON that is no object (array, string, number, null). An empty
# body counts as {} like in the parsers. The texts are fixed -- the
# decoder's own message never reaches a client (k81). A protocol with its
# own error for a broken body (A2A's JSON-RPC parse error) overrides it.
sub request_body_error {
  my ($self, $body_ref) = @_;
  my $body = $$body_ref;
  return unless defined $body && length $body;
  my $data = eval { JSON::MaybeXS->new( utf8 => 1 )->decode($body) };
  return 'request body is not valid JSON' if $@;
  return 'request body must be a JSON object' unless ref $data eq 'HASH';
  return;
}

# The code of a status in the error vocabulary ACP and AG-UI share.
sub _status_error_code {
  my ($self, $status) = @_;
  return $status == 404 ? 'not_found' : $status >= 500 ? 'server_error' : 'invalid_input';
}

sub format_error_response {
  my ($self, $status, $message, $request) = @_;
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

version 1.103

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

=head2 request_body_error

    my $reason = $proto->request_body_error(\$body);

Returns why the body cannot be a chat request (not JSON, or JSON that is no
object) as a fixed text without the decoder's message, else nothing. Knarr
answers it with a 400 in the protocol's error shape (k81). A2A overrides it
to nothing: its parse failure is a JSON-RPC error of its own.

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

    my ($status, \%headers, $body) = $proto->format_error_response( 504, 'upstream timed out', $request );

An error answer in this protocol's shape. Default: the OpenAI wire's
C<{"error":{"message":...}}>; Anthropic answers
C<{"type":"error","error":{"type":...,"message":...}}>, Ollama a plain
C<{"error":"..."}>, A2A a JSON-RPC response with an C<error> object. The
optional third argument is the parsed L<Langertha::Knarr::Request> (absent
when the request never parsed); the optional fourth is the request's raw body
(see L</error_uses_body>). A2A takes the JSON-RPC C<id> from them. ACP answers
its C<Error> object C<{"code":...,"message":...}> (C<server_error>,
C<not_found>, C<invalid_input>), AG-UI the C<RUN_ERROR> event as JSON. Knarr
answers every error of its own through it, the C<401> and the C<500> of a
failed backend included (see L<Langertha::Knarr/ERRORS>).

=head2 error_uses_body

True for a protocol whose error answer reads the request body (A2A's
JSON-RPC C<id>, which is in the body even when the request was rejected
before it parsed): the PSGI adapter reads the body for such an error only
then. Default false.

=head2 format_stream_error

    my $bytes = $proto->format_stream_error( 504, 'upstream timed out', $request );

The frame that tells a client its stream failed after the response
headers went out, or C<''> (the default) when the protocol has none.
OpenAI sends C<data: {"error":{...}}>, Anthropic an C<event: error>,
Ollama an C<{"error":"..."}> line, A2A a JSON-RPC error event, ACP
C<event: run.failed>, AG-UI C<RUN_ERROR>. The frame is the end of the
stream: no end marker follows it. A routed stream whose handler fails after
its first chunk ends with it (500, or the status of the failure's
category), and so does the raw passthrough when the upstream stops feeding
its stream.

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

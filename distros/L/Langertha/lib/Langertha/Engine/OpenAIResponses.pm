package Langertha::Engine::OpenAIResponses;
# ABSTRACT: OpenAI Responses API (reasoning models like gpt-5.5-pro)
our $VERSION = '0.503';
use Moose;

extends 'Langertha::Engine::OpenAI';

with 'Langertha::Role::ResponsesCompatible', 'Langertha::Role::ServerTools';


# Protocol variant of OpenAI: shares the vendor's API key.
sub api_key_env { 'LANGERTHA_OPENAI_API_KEY' }

# The Responses envelope role can stream (typed SSE), but this engine has never
# supported it. Opt out: stream_format => undef, and clear the streaming flag
# that Role::Streaming (inherited via Engine::OpenAI) would otherwise advertise
# (ADR 0002 escape hatch). Both together keep supports('streaming') honest.
sub stream_format { return undef }

around engine_capabilities => sub {
    my ( $orig, $self, @rest ) = @_;
    my $caps = $self->$orig(@rest);
    delete $caps->{streaming};
    return $caps;
};

# Tool-result PDFs (karr k361): function_call_output.output takes an
# input_file part (API reference, FunctionCallOutput: "string or array of
# ResponseInputTextContent or ResponseInputImageContent or
# ResponseInputFileContent", developers.openai.com/api/reference/resources/
# responses/methods/create; data: URL + filename per the PDF-files guide,
# developers.openai.com/api/docs/guides/pdf-files; fetched 2026-09-30).
# Docs-derived, not live-verified. Role::Tools still requires image_input
# (the guide names vision models for PDF input). Perplexity shares the
# envelope but not this part, so the flag sits here, not on the role.
sub _tool_result_pdf_on_wire { 1 }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OpenAIResponses - OpenAI Responses API (reasoning models like gpt-5.5-pro)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::OpenAIResponses;

    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => $ENV{OPENAI_API_KEY},
        model   => 'gpt-5.5-pro',   # reasoning-only model
    );

    my $response = $engine->simple_chat('Hello');
    print $response;

=head1 DESCRIPTION

Provides access to OpenAI's Responses API endpoint (C<POST /v1/responses>)
for reasoning-only models like C<gpt-5.5-pro>, C<o3-pro>, and future
C<-pro> SKUs that are not available on the Chat Completions endpoint
(C</v1/chat/completions>).

Unlike L<Langertha::Engine::OpenAI> which calls C</v1/chat/completions>, this
engine speaks the Open-Responses wire envelope: C<input> instead of
C<messages>, top-level C<instructions>, flat tool objects, and an C<output[]>
array with type discriminators. That envelope lives in
L<Langertha::Role::ResponsesCompatible> (parallel to
L<Langertha::Role::OpenAICompatible>); this engine is a thin shell that inherits
OpenAI's Bearer auth, API key and model list from L<Langertha::Engine::OpenAI>,
composes the Responses envelope on top, and opts out of streaming.

This engine returns a L<Langertha::Response> that is shape-compatible with
the chat path, so existing consumers (including Goldmine's C<complete>
method) work without modification. Reasoning tokens are normalized to
C<completion_tokens_details.reasoning_tokens> for cost lookup compatibility.

=head2 Structured output

Structured output goes under C<text.format> (a flat json_schema, not the
Chat-Completions nested shape); the Responses API has no C<response_format>
param. See L<Langertha::Role::ResponsesCompatible/_responses_format_kwargs>.

=head2 Server-side tools

OpenAI's hosted tools (C<web_search>, C<file_search>, C<code_interpreter>,
C<image_generation>, remote C<mcp>, ...) are supported: this engine composes
L<Langertha::Role::ServerTools>, so C<supports('server_tools')> is true. Pass
them per request in C<tools> (native hashes or L<Langertha::ServerTool>
objects, mixed freely with function tools), or once on the engine:

    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key      => $ENV{OPENAI_API_KEY},
        model        => 'gpt-5.6-luna',
        server_tools => [ { type => 'web_search' } ],
    );
    my $r = $engine->simple_chat('What is the current stable Perl 5 release?');
    say $_->{url} for @{ $r->citations // [] };

The provider runs them within the request. What it did lands on
L<Langertha::Response/server_tool_calls>, the C<url_citation> annotations of
the answer on L<Langertha::Response/citations>; neither ever reaches
L<Langertha::Response/tool_calls>, so C<chat_with_tools_f> executes only
function calls and echoes the server items back unchanged on the next turn.
The search sources of a C<web_search_call> (request them with
C<< include => ['web_search_call.action.sources'] >>) stay on that call's
C<data>.

A remote C<mcp> tool must say C<< require_approval => 'never' >>: OpenAI's
default is C<always>, which answers with an C<mcp_approval_request> the client
has to confirm, and Langertha has no approval flow yet. Anything else croaks
before the request is sent (checked by L<Langertha::ServerTool/to>).

=head2 Function call output shape

The Responses API emits C<function_call> as a top-level C<output[]> item
(real reasoning models) or nested inside a message item (older fixtures);
C<chat_response> and L<Langertha::ToolCall/extract> walk both. Streaming is
not supported — L<Langertha::Role::ResponsesCompatible> can stream the
envelope, but this engine opts out (see below).

=head1 SEE ALSO

=over

=item * L<Langertha::Role::ResponsesCompatible> - the Open-Responses wire envelope

=item * L<Langertha::Role::ServerTools> / L<Langertha::ServerTool> - server-side tools

=item * L<Langertha::Engine::OpenAI> - Chat Completions endpoint (for non-reasoning models)

=item * L<Langertha::Engine::Perplexity> - the other Responses-envelope consumer (Agent API)

=item * L<Langertha::ToolCall> - Tool call extraction from Responses format

=item * L<Langertha::ToolChoice/to_responses> - Responses tool_choice serialization

=item * L<Langertha::Tool/to_responses> - Responses tool serialization

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Langertha::Engine::SGLang;
# ABSTRACT: SGLang inference server
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools',
     'Langertha::Role::Embedding',
     'Langertha::Role::Runtime::MetricsPoll',
     'Langertha::Role::RuntimeKnobs';

# SGLang's per-request runtime knobs: cache_salt, extra_key, priority,
# return_cached_tokens_details. Speculative decoding is a server-launch flag
# (--speculative-*), not a request knob — see Langertha::Runtime::Knobs.
sub _build_knob_wire_format { 'sglang' }


has '+url' => (
  required => 1,
);

sub default_model { 'default' }
# No fixed embedding model: the caller's model, else no model field (the vLLM
# rule, k297); the server embeds with the model it was launched with (k309).
sub default_embedding_model { undef }

# LANGERTHA_SGLANG_API_KEY is derived from the class name; a local server
# needs no key, a --api-key-protected `sglang.launch_server` does.
sub api_key_required { 0 }

sub _build_api_key {
  return $ENV{LANGERTHA_SGLANG_API_KEY};
}

sub _build_supported_operations {[qw(
  createChatCompletion
  createCompletion
  createEmbedding
)]}

# tool_choice: all four forms stay. ChatCompletionRequest.tool_choice is
# auto|required|none or a named function, default auto
# (python/sglang/srt/entrypoints/openai/protocol.py, source-checked 2026-09-25,
# karr k244), and serving_chat honors none. The tool_parser docs list only
# required and named because those two need the grammar backend (xgrammar, the
# default); that omission, not a wire rejection, was why k138 cleared auto and
# none. Every tool field needs the server started with --tool-call-parser.
# prompt_cache_key (OpenAI's cache-routing hint) is not a field of SGLang's
# ChatCompletionRequest, a pydantic model that silently drops unknown keys
# (python/sglang/srt/entrypoints/openai/protocol.py, checked 2026-09-25, karr
# #200). Prefix-cache control is cache_salt / extra_key via RuntimeKnobs.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{prompt_cache_key};
  # image_input (k266, ADR 0019): self-hosted: the served model is launch state the client cannot see, so no claim.
  delete $caps->{image_input};
  return $caps;
};

# karr k245: SGLang rejects tool_choice 'required' or a named tool together
# with an output constraint ("tool_choice 'required' or a named tool cannot be
# combined with response_format, regex, or ebnf", ValueError in
# python/sglang/srt/entrypoints/openai/protocol.py since 307a90f6d3 /
# 17ba2c2e7c, source-checked 2026-09-25): json_schema, json_object (becomes
# json_schema '{"type":"object"}') and structural_tag constrain, text does not.
# tool_choice auto + response_format is accepted. The server exempts parsers
# whose tool constraint is full_assistant_ebnf; that is a launch flag Langertha
# cannot see, so the rule holds for every model (qr//), like Groq/Cerebras.
my %SGLANG_CONSTRAINING_RF = map { $_ => 1 } qw( json_schema json_object structural_tag );

sub model_capability_exclusions {
  return (
    qr// => \&_exclude_forced_tool_choice_with_response_format,
  );
}

sub _exclude_forced_tool_choice_with_response_format {
  my ( $self, %request ) = @_;
  return unless $request{has_tools} && $request{tool_choice_forced};
  my $rf   = $request{response_format};
  my $type = ( ref $rf eq 'HASH' ) ? ( $rf->{type} // '' ) : '';
  return unless $SGLANG_CONSTRAINING_RF{$type};
  croak "".(ref $self)." cannot combine a forced tool_choice (required or a "
    ."named tool) with response_format $type in one request: the SGLang server "
    ."rejects it (the tool-call constraint and the output constraint cannot both "
    ."be honored) with HTTP 400. Use tool_choice auto, or drop the response_format.";
}

__PACKAGE__->meta->make_immutable;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::SGLang - SGLang inference server

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::SGLang;

    # 1. Simple chat
    my $sglang = Langertha::Engine::SGLang->new(
        url   => 'http://localhost:30000/v1',
        model => 'Qwen/Qwen2.5-7B-Instruct',
    );

    print $sglang->simple_chat('Say something nice');

    # 2. Streaming
    $sglang->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a haiku about Perl');

    # 3. MCP tool calling (requires a tool-call-parser-compatible model)
    use Future::AsyncAwait;

    my $sglang = Langertha::Engine::SGLang->new(
        url         => 'http://localhost:30000/v1',
        model       => 'Qwen/Qwen2.5-7B-Instruct',
        mcp_servers => [$mcp],
    );

    my $response = await $sglang->chat_with_tools_f('Add 7 and 15');

    # 4. Multimodal input (vision-capable models served by SGLang)
    use Langertha::Content::Image;

    my $img  = Langertha::Content::Image->from_url('https://example.com/cat.jpg');
    my $resp = await $sglang->simple_chat_f({
        role    => 'user',
        content => [ 'What is in this image?', $img ],
    });

    # 5. Prometheus /metrics scraping (Runtime::MetricsPoll)
    my $records = await $sglang->poll_metrics_f('sglang:');

    # 6. Embeddings (server launched with an embedding model)
    my $embedder = Langertha::Engine::SGLang->new(
        url   => 'http://localhost:30000/v1',
        model => 'Alibaba-NLP/gte-Qwen2-1.5B-instruct',
    );
    my $vector  = $embedder->simple_embedding('Some text to embed');
    my $vectors = $embedder->simple_embedding([ 'first', 'second' ]);

=head1 DESCRIPTION

Adapter for SGLang's OpenAI-compatible endpoint.
SGLang is typically exposed as C</v1/chat/completions> with optional
tool-calling support depending on model/backend setup.

Extends L<Langertha::Engine::OpenAIBase> (which composes
L<Langertha::Role::OpenAICompatible>, L<Langertha::Role::OpenAPI>,
L<Langertha::Role::Models>, L<Langertha::Role::Temperature>,
L<Langertha::Role::ResponseSize>, L<Langertha::Role::SystemPrompt>,
L<Langertha::Role::ResponseFormat>, L<Langertha::Role::Streaming>,
L<Langertha::Role::Chat>, L<Langertha::Role::ReasoningEffort>, and
L<Langertha::Role::PromptCache>); SGLang itself additionally composes
L<Langertha::Role::Tools> (MCP tool calling), L<Langertha::Role::Embedding>
(OpenAI-compatible C</v1/embeddings>) and
L<Langertha::Role::Runtime::MetricsPoll> (Prometheus C</metrics> scrape).

Supports chat, streaming, tool calling, embeddings, structured output,
multimodal input, and Prometheus /metrics scraping. Transcription is not
exposed on the OpenAI-compatible surface SGLang serves.

Only C<url> is required. Use the full C</v1> base URL.
No API key is required for local setups.

See L<https://docs.sglang.ai/> for installation and configuration details.

=head1 EMBEDDINGS

Composes L<Langertha::Role::Embedding>. SGLang serves C</v1/embeddings> when
launched with an embedding model (decoder-style models also need
C<--is-embedding>). The request carries C<embedding_model> if you set it,
else C<model> if you set it, else no C<model> field at all: the server
embeds with the model it serves. A string returns one vector, an ArrayRef of
strings one vector per input, in input order.

=head1 CAPABILITIES

Advertised flags (derived from composed roles via L<Langertha::Role::Capabilities>):

=over 4

=item * C<chat> — L<Langertha::Role::Chat>

=item * C<streaming> — L<Langertha::Role::Streaming>

=item * C<tools_native> + C<tool_choice_{auto,any,none,named}> — L<Langertha::Role::Tools>
(tool calling needs the server started with C<--tool-call-parser>; C<any> (wire
C<required>) and a named tool also need the grammar backend, xgrammar by default)

=item * C<embedding> — L<Langertha::Role::Embedding>

=item * C<runtime_metrics> — L<Langertha::Role::Runtime::MetricsPoll>

=item * C<response_format_{json_object,json_schema}> — L<Langertha::Role::ResponseFormat>

=item * C<temperature> — L<Langertha::Role::Temperature>

=item * C<reasoning_effort> — L<Langertha::Role::ReasoningEffort>

=item * C<response_size>, C<system_prompt>, C<parallel_tool_use>, C<context_size>, C<seed>
— generation-parameter knobs the engine will honour

=back

A forced C<tool_choice> (C<required> or a named tool) together with a
C<response_format> of C<json_schema>, C<json_object> or C<structural_tag>
croaks before the request is sent: the SGLang server rejects that combination
with HTTP 400. C<tool_choice> C<auto> with a C<response_format> is sent.

=head1 SEE ALSO

=over

=item * L<https://docs.sglang.ai/> - SGLang documentation

=item * L<Langertha::Engine::OpenAIBase> - Base class for OpenAI-compatible engines

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Role::Runtime::MetricsPoll> - Prometheus /metrics scraper

=item * L<Langertha::Engine::vLLM> - Sister self-hosted OpenAI-compatible engine (also Embedding + MetricsPoll)

=item * L<Langertha::Engine::LlamaCpp> - Sister self-hosted OpenAI-compatible engine (also Embedding + MetricsPoll)

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

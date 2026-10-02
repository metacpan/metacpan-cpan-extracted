package Langertha::Engine::vLLM;
# ABSTRACT: vLLM inference server
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools',
     'Langertha::Role::Embedding',
     'Langertha::Role::Runtime::MetricsPoll',
     'Langertha::Role::RuntimeKnobs';

# vLLM's only per-request runtime knob is cache_salt (prefix-cache isolation,
# vLLM v1.x+). Speculative decoding is a server-launch flag
# (--speculative-config), not a request knob — see Langertha::Runtime::Knobs.
sub _build_knob_wire_format { 'vllm' }

# prompt_cache_key (OpenAI's cache-routing hint) is not a field of vLLM's
# ChatCompletionRequest: the pydantic model accepts extra keys and ignores them
# with a debug log (vllm/entrypoints/serve/engine/protocol.py; only the
# /v1/responses protocol declares it; checked 2026-09-25, karr #200). The
# prefix-cache lever here is cache_salt via RuntimeKnobs, so clear the flag
# (ADR 0002 layer 2). VLLMHook inherits this.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{prompt_cache_key};
  # image_input (k266, ADR 0019): self-hosted: the served model is launch state the client cannot see, so no claim.
  delete $caps->{image_input};
  return $caps;
};


has '+url' => (
  required => 1,
);

sub default_model { 'default' }
# No fixed embedding model: the caller's model, else no model field (k297).
sub default_embedding_model { undef }

# LANGERTHA_VLLM_API_KEY is derived from the class name; a local server needs
# no key, a --api-key-protected `vllm serve` does.
sub api_key_required { 0 }

sub _build_api_key {
  return $ENV{LANGERTHA_VLLM_API_KEY};
}

sub _build_supported_operations {[qw(
  createChatCompletion
  createCompletion
  createEmbedding
)]}

__PACKAGE__->meta->make_immutable;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::vLLM - vLLM inference server

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::vLLM;

    # 1. Simple chat
    my $vllm = Langertha::Engine::vLLM->new(
        url           => 'http://localhost:8000/v1',
        system_prompt => 'You are a helpful assistant',
    );

    print $vllm->simple_chat('Say something nice');

    # 2. Streaming
    $vllm->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a haiku about Perl');

    # 3. MCP tool calling (requires server started with tool-call-parser)
    use Future::AsyncAwait;

    my $vllm = Langertha::Engine::vLLM->new(
        url         => 'http://localhost:8000/v1',
        model       => 'Qwen/Qwen2.5-3B-Instruct',
        mcp_servers => [$mcp],
    );

    my $response = await $vllm->chat_with_tools_f('Add 7 and 15');

    # 4. Multimodal input (vision-capable models: LLaVA, Qwen-VL, PaliGemma)
    use Langertha::Content::Image;

    my $img  = Langertha::Content::Image->from_url('https://example.com/cat.jpg');
    my $resp = await $vllm->simple_chat_f({
        role    => 'user',
        content => [ 'What is in this image?', $img ],
    });

    # 5. Reasoning models (Qwen3, DeepSeek-R1, QwQ — server needs
    #    --reasoning-parser matching the model; reasoning_effort maps to
    #    enable_thinking via the chat template). simple_chat takes messages
    #    only — set the control on the engine, or hand it to chat_f.
    my $thinker = Langertha::Engine::vLLM->new(
        url              => 'http://localhost:8000/v1',
        reasoning_effort => 'high',
    );

    print $thinker->simple_chat('Solve step by step: what is 7 factorial?');

    # … or as a per-request control:
    my $reasoned = await $vllm->chat_f(
        messages         => ['Solve step by step: what is 7 factorial?'],
        reasoning_effort => 'high',
    );

    # 6. Embeddings (for embedding models: BAAI/bge-*, intfloat/e5-*, …)
    my $vector = $vllm->simple_embedding('Some text to embed');

    # 7. Prometheus /metrics scraping (Runtime::MetricsPoll)
    my $records = await $vllm->poll_metrics_f('vllm:');
    # Returns ArrayRef of { name, type, value, labels } parsed from
    # GET <url-stripped-of-/v1>/metrics.

    # 8. vLLM-Hook sub-engine (IBM vLLM-Hook plugin: hidden states, qk, steer)
    use Langertha::Engine::VLLMHook;
    my $hooked = Langertha::Engine::VLLMHook->new(
        url        => 'http://localhost:8770/v1',
        vllm_xargs => { output_hidden_states => JSON::MaybeXS::true() },
    );

=head1 DESCRIPTION

Provides access to vLLM, a high-throughput inference engine for large
language models. Extends L<Langertha::Engine::OpenAIBase> (which composes
L<Langertha::Role::OpenAICompatible>, L<Langertha::Role::OpenAPI>,
L<Langertha::Role::Models>, L<Langertha::Role::Temperature>,
L<Langertha::Role::ResponseSize>, L<Langertha::Role::SystemPrompt>,
L<Langertha::Role::ResponseFormat>, L<Langertha::Role::Streaming>,
L<Langertha::Role::Chat>, L<Langertha::Role::ReasoningEffort>, and
L<Langertha::Role::PromptCache>); vLLM itself additionally composes
L<Langertha::Role::Tools> (MCP tool calling), L<Langertha::Role::Embedding>
(OpenAI-compatible C</v1/embeddings> for embedding models), and
L<Langertha::Role::Runtime::MetricsPoll> (Prometheus C</metrics> scrape).

Supports chat, streaming, tool calling, embeddings, multimodal input,
reasoning models, and Prometheus /metrics scraping.

Only C<url> is required. The URL must include the C</v1> path prefix
(e.g., C<http://localhost:8000/v1>). Since vLLM serves exactly one model
(configured at server startup), no model name or API key is needed.

=head1 TOOL CALLING

MCP tool calling requires the vLLM server to be started with
C<--enable-auto-tool-choice> and C<--tool-call-parser> matching the model
(C<hermes> for Qwen2.5/Hermes, C<llama3> for Llama, C<mistral> for Mistral).

=head1 EMBEDDINGS

Composes L<Langertha::Role::Embedding>. vLLM exposes an OpenAI-compatible
C</v1/embeddings> endpoint when started with an embedding model
(BAAI/bge-*, intfloat/e5-*, …). The request carries C<embedding_model> if
you set it, else C<model> if you set it, else no C<model> field at all: the
server embeds with the model it serves. (vLLM 0.10/0.11 answer 404 to a
C<model> that is not a served name, such as the C<'default'> placeholder.)

=head1 REASONING MODELS

vLLM serves reasoning models through the OpenAI-compatible chat completions
endpoint. C<reasoning_effort> (L<Langertha::Role::ReasoningEffort>,
L<Langertha::Reasoning>, wire format C<openai>) is honored on the body —
vLLM translates the value into C<enable_thinking> via the chat template:

    reasoning_effort low|medium|high   ->  enable_thinking = true
    reasoning_effort none              ->  enable_thinking = false
    (unset)                            ->  enable_thinking not injected

The thought itself comes back in the C<reasoning> response field — mainline
vLLM renamed it from C<reasoning_content> to C<reasoning> in v0.16.0, and
both spellings are read — surfaced on C<< $response->thinking >>. It is only
populated when the server was started with the matching C<--reasoning-parser>.

Supported reasoning-model families (vLLM's own table — verify against
L<https://docs.vllm.ai/en/latest/features/reasoning_outputs/> for the
exact list as new models land):

=over 4

=item * Qwen3 (C<Qwen3-Instruct> / C<Qwen3-Thinking>) — wire
C<reasoning_effort> honored.

=item * DeepSeek-R1 (native) and DeepSeek-R1-Distill-* — wire
C<reasoning_effort> honored.

=item * QwQ-32B — wire C<reasoning_effort> honored (served via the
C<deepseek_r1> reasoning parser).

=item * Gemma 4, IBM Granite 3.2, DeepSeek-V3.1 / V4 — also honor the
parameter via the same chat-template auto-injection path.

=back

The server MUST be started with the matching C<--reasoning-parser> flag
for the loaded model (C<deepseek_r1> for DeepSeek-R1 / QwQ, C<qwen3>
for Qwen3 thinking, etc.) — without it, the model emits reasoning
content but Langertha cannot surface it on L<Langertha::Response>.
See vLLM's reasoning-outputs docs for the canonical flag list.

Per ADR 0009 the wire format is C<openai> on vLLM; engines diverging
(Anthropic, Gemini) carry their own C<reasoning_wire_format> tag and
serialize independently.

=head1 METRICS

Composes L<Langertha::Role::Runtime::MetricsPoll>. vLLM serves Prometheus
text-format metrics at C<GET <url-stripped-of-/v1>/metrics>; pass a prefix
to L</poll_metrics_f> (e.g. C<'vllm:'> for the engine's own gauges) or
filter downstream via L<Langertha::Runtime::Metrics/filter_prefix>.

=head1 SUB-ENGINE: VLLMHook

L<Langertha::Engine::VLLMHook> extends this engine for servers running the
IBM vLLM-Hook plugin (hidden_states / qk / steer probes); it injects a
top-level C<vllm_xargs> field and lifts captured tensors onto
L<Langertha::Response/probes>. See ADR 0004 for the seam.

See L<https://docs.vllm.ai/> for installation and configuration details.

=head1 CAPABILITIES

Advertised flags (derived from composed roles via L<Langertha::Role::Capabilities>):

=over 4

=item * C<chat> — L<Langertha::Role::Chat>

=item * C<streaming> — L<Langertha::Role::Streaming>

=item * C<tools_native> + C<tool_choice_{auto,any,none,named}> — L<Langertha::Role::Tools>

=item * C<embedding> — L<Langertha::Role::Embedding>

=item * C<runtime_metrics> — L<Langertha::Role::Runtime::MetricsPoll>

=item * C<response_format_{json_object,json_schema}> — L<Langertha::Role::ResponseFormat>

=item * C<temperature> — L<Langertha::Role::Temperature>

=item * C<reasoning_effort> — L<Langertha::Role::ReasoningEffort>; honored by Qwen3 / DeepSeek-R1 / QwQ / Gemma 4 / Granite 3.2 when vLLM is started with C<--reasoning-parser>. See L</REASONING MODELS>.

=item * C<response_size>, C<system_prompt>, C<parallel_tool_use>, C<context_size>, C<seed>
— generation-parameter knobs the engine will honour

=back

=head1 SEE ALSO

=over

=item * L<https://docs.vllm.ai/> - vLLM documentation

=item * L<Langertha::Engine::OpenAIBase> - Base class for OpenAI-compatible engines

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Role::Embedding> - Embedding request/response interface

=item * L<Langertha::Role::Runtime::MetricsPoll> - Prometheus /metrics scraper

=item * L<Langertha::Engine::VLLMHook> - Sub-engine for the IBM vLLM-Hook plugin

=item * L<Langertha::Engine::LlamaCpp> - Sister self-hosted OpenAI-compatible engine (also Embedding + MetricsPoll)

=item * L<Langertha::Engine::SGLang> - Sister self-hosted OpenAI-compatible engine (also MetricsPoll)

=item * L<Langertha::Engine::OllamaOpenAI> - Ollama's OpenAI-compatible endpoint

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

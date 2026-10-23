# ADR 0038 — The core stream request asks for the token usage where the engine claims `stream_usage`

- Status: accepted
- Date: 2026-10-19
- Tags: streaming, capabilities, usage, openai-chat, roles
- Cross-links: ADR 0002, ADR 0016, ADR 0019, ADR 0018

## Context

On the OpenAI chat wire a stream reports its token usage only when the request carries
`stream_options: {"include_usage": true}`. The provider then sends one more frame after the
finish chunk, with an empty `choices` list and the whole request's `usage`. Since k298,
`Role::OpenAICompatible::parse_stream_chunk` reads that frame into a content-less, non-final
`Stream::Chunk` with `usage`, and `Role::Chat::aggregate_usage` finds it. But Langertha's own
`chat_stream_request` never sent the option. Every streamed answer on an OpenAI-wire engine came
without usage unless the caller knew to pass `stream_options` by hand. That includes
langertha-knarr, which routes its clients' streams through `chat_stream_request`, so its
Langfuse traces of routed streams had no token counts.

Sending the option everywhere is not safe. Some OpenAI-compatible APIs reject body fields their
schema does not list. Mistral's `ChatCompletionRequest`, for example, is
`additionalProperties: false` and has no `stream_options`. So the option needs a gate.

## Decision

1. **A new capability `stream_usage` from a new capability role `Langertha::Role::StreamUsage`**
   (entry in `%ROLE_TO_CAPS`). It means: *`chat_stream_request` asks the provider for the
   stream's token usage (OpenAI chat wire: `stream_options.include_usage`); the usage arrives as
   the stream's last chunk.* The role has no code. Its job is to make the claim derivable from
   `does($role)` (ADR 0002). By ADR 0016 decision 2 a separable feature is a role from day one.
2. **The core sets the option itself.** `Role::OpenAICompatible::chat_stream_request` emits
   `stream_options => { include_usage => JSON->true }` when `$self->supports('stream_usage')`.
   It sits *before* `%extra`, so a `stream_options` the caller passes replaces it whole
   (`{ include_usage => false }` turns the usage off for one request). The non-streaming
   `chat_request` never carries it: vLLM, xAI and Groq document it as valid only with
   `stream: true`.
3. **Each engine composes the role with `with`, per provider documentation; when in doubt, OFF.**
   The role is not composed on `OpenAIBase`. An engine claims it only where the provider's API
   reference names `stream_options.include_usage` for chat completions, or, for a self-hosted
   server, where its request schema in the source names it.
4. **`OpenAIResponses` clears the flag** in its existing `around engine_capabilities`, next to
   `streaming`. It gets the role from `Engine::OpenAI`, but its `chat_stream_request` is
   `Role::ResponsesCompatible`'s. The Responses API has no `include_usage`, because a Responses
   stream reports usage in `response.completed` unasked. And the engine does not stream at all.
   Leaving the flag would claim a request field that this engine's wire never carries.
5. **The manifest does not publish `stream_usage`** (`Manifest::Builder` allowlist; classified
   in `t/96_manifest_builder.t`). It describes Langertha's request builder, not a model. Behind a
   proxy's public URL, whether a stream reports usage is the proxy's behavior.

### Engine decisions (checked 2026-10-19)

| Engine | `stream_usage` | Source |
|---|---|---|
| OpenAI | on | https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create (`include_usage`: "an additional chunk will be streamed before the data: [DONE] message") |
| vLLM (+ VLLMHook) | on | vllm `vllm/entrypoints/openai/chat_completion/protocol.py` (`ChatCompletionRequest.stream_options: StreamOptions`, `StreamOptions.include_usage`) |
| SGLang | on | sglang `python/sglang/srt/entrypoints/openai/protocol.py` (`ChatCompletionRequest.stream_options`, `StreamOptions.include_usage`) |
| Virtual (+ Mock) | on | Langertha's own engine: `virtual_stream_chunks` serves the usage frame on `include_usage` |
| DeepSeek | on | https://api-docs.deepseek.com/api/create-chat-completion (`stream_options.include_usage`; the last chunk carries the usage either way) |
| XAI | on | https://docs.x.ai/openapi.json (`ChatRequest.stream_options` → `StreamOptions.include_usage`) |
| Groq | on | https://console.groq.com/docs/api-reference (chat create, `ChatCompletionStreamOptions.include_usage`; `x_groq.usage` comes on the last chunk either way) |
| OllamaOpenAI | on | https://docs.ollama.com/api/openai-compatibility (`/v1/chat/completions` supported fields: `stream_options` / `include_usage`) |
| LlamaCpp | on | llama.cpp `tools/server/server-schema.cpp` (`field_nested("stream_options")` → `field_bool("include_usage")`). Source, not the README, which does not list it. The schema ignores unknown keys, so older builds without the field do not reject it |
| Moonshot | on | https://platform.kimi.ai/docs/api/chat ("Use `stream_options: {"include_usage": true}` to receive an additional `usage` field in the last chunk") |
| MiniMax | on | https://platform.minimax.io/docs/api-reference/text-chat-openai (`ChatCompletionReq.stream_options.include_usage`) |
| Scaleway | on | https://www.scaleway.com/en/developers/api/generative-apis/v1/schema.yml (`ChatCompletionStreamOptions.include_usage`; only `include_obfuscation` is listed as unsupported) |
| TSystems | on | https://docs.llmhub.t-systems.net/guides/streaming/ and https://llm-server.llmhub.t-systems.net/openapi.json. Documentation-derived, not live-verified (no key, see CLAUDE.md) |
| HuggingFace | on | https://huggingface.co/docs/inference-providers/tasks/chat-completion (payload: `stream_options.include_usage`) |
| Mistral | off | https://docs.mistral.ai/openapi.yaml: no `stream_options`, and `ChatCompletionRequest` is `additionalProperties: false` |
| Cerebras | off | https://inference-docs.cerebras.ai/api-reference/chat-completions: not in the body schema |
| OpenRouter | off | https://openrouter.ai/docs/api/api-reference/chat/create-a-chat-completion: `include_usage` is marked deprecated, "has no effect. Full usage details are always included" |
| LMStudioOpenAI | off | https://lmstudio.ai/docs/developer/openai-compat/chat-completions: the parameter list has no `stream_options` |
| NousResearch | off | https://portal.nousresearch.com/api-docs: no readable field list was found |
| Hetzner | off | https://docs.hetzner.com/general/company-and-policy/experiments/inference/: no parameter list |
| AKIOpenAI | off | https://aki.io/docs/compatibility/openai-api-compatibility/: only `model, messages, temperature, max_tokens, stream, stop` |
| Replicate | off | https://api.replicate.com/openapi.json: no chat-completions path documented at all |
| OpenAIResponses | off (cleared) | Decision 4 |

Engines with their own `chat_stream_request` are out of scope and unchanged. Their wire either
has no such option or reports usage unasked: `AnthropicCompatible` (`message_start` /
`message_delta`), Gemini (`usageMetadata`), Ollama native (`done` frame), LM Studio native,
Perplexity and AKI.

## Rationale

- **Core, not the caller.** Every Langertha user gets the usage of a stream, not only knarr. The
  wire knowledge (field name, placement, "stream only") lives in one place, the same envelope
  that already parses the usage frame (k298). The request side and the response side of one wire
  feature now sit together.
- **A capability, not an unconditional field.** The schema of one provider rejects unknown keys,
  and the docs of several others do not list the option. ADR 0002 already holds a sanctioned
  per-engine yes/no that `supports()` can query, so a second mechanism (an engine attribute, a
  per-engine `around chat_stream_request`) would duplicate it. Since k239/k241, field emission
  follows the claimed capability (ADR 0002 Update), and this follows that pattern.
- **Off when in doubt.** A missing usage frame costs a trace its token counts. A rejected field
  costs the whole stream with a 400. The asymmetry decides the default.
- **Caller wins.** A caller that passes `stream_options` has stated its wire intent. Replacing
  the whole value instead of merging keeps that intent exact. The same rule holds for every other
  `%extra` key of the builder.

### Alternatives considered

- **Only knarr sets the option** (knarr passes `stream_options` into `chat_stream_request` for
  routed streams). Rejected. Every other consumer (langertha-raider, scripts, `Langertha::Chat`)
  would keep losing the usage. Knarr would need its own per-provider list of which upstream
  accepts the field, which duplicates the capability registry outside core, where it drifts.
- **Always send the option on the OpenAI wire.** Rejected: Mistral's strict schema, and
  undocumented servers (LM Studio, AKI.IO, Hetzner, Cerebras) put the stream at risk.
- **Compose the role on `OpenAIBase` and clear it per engine.** Rejected. An opt-out list makes
  every new OpenAI-compatible engine claim an unverified field by default, which is the opposite
  of decision 3.
- **No role, a flag set in `around engine_capabilities`.** Rejected by ADR 0002/0016: a
  capability flag without a role has no place in the registry and cannot be derived from
  composition.

## Consequences

- Streams on the "on" engines carry one more frame, a usage chunk after the `is_final` chunk.
  Code that took `$chunks->[-1]` as the final chunk on those engines now sees the usage chunk.
  `aggregate_usage` and an `is_final` scan are the documented ways to read a stream
  (`t/73_virtual_stream.t` turns the usage off where it pins the final chunk).
- DeepSeek and Moonshot, with the option set, also put `usage: null` on every other chunk. The
  parser already ignores a non-hash `usage`.
- Groq sends the top-level usage frame next to `x_groq.usage`. Groq's `around parse_stream_chunk`
  already prefers a top-level usage; both describe the same request.
- A flag cleared for want of documentation is added once a provider documents the field (same
  rule as the k239 Update of ADR 0002). Pinned per engine in `t/43_stream_usage_request.t`. A
  flip there is a decision change and belongs in the table above.

## Future work

- The decisions are documentation-derived. None was live-verified in this change (TSystems
  cannot be). A live stream test per keyed provider would confirm the usage frame arrives.

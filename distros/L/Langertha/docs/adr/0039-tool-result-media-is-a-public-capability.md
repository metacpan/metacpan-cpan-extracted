# ADR 0039 — Images and PDFs in tool results are public capabilities: `tool_result_images` / `tool_result_pdf`

- Status: accepted
- Date: 2026-10-19
- Tags: capabilities, tools, tool-results, image-input, roles
- Cross-links: ADR 0001, ADR 0002, ADR 0016, ADR 0019, ADR 0032, ADR 0038, CONTEXT.md
- karr: #380

## Context

A tool can return an image or a PDF (an MCP `image` item, or an embedded resource with an
`application/pdf` blob). Since k344, k359, k361 and k364, `Langertha::ToolResult->to` serializes
that content natively on the wires that have a form for it: the `anthropic` wire as `image` /
`document` blocks inside `tool_result.content`, the `responses` wire as `input_image` /
`input_file` parts of `function_call_output.output`, and the `gemini` wire as
`functionResponse.parts[].inlineData`. Everywhere else it stays the k336 text placeholder.

Which form a tool loop uses was decided by private predicates in `Role::Tools`:
`_tool_result_images_on_wire` (default 1; AKIAnthropic 0; Gemini only for `gemini-3`),
`_tool_result_pdf_on_wire` (default 0; OpenAIResponses 1; Gemini as for images; Perplexity 0),
each combined with `supports('image_input')`, plus `_tool_result_source_blocks_on_wire` for the
`anthropic` PDF `document` block. None of this was visible from outside.

langertha-raider needs the answer before it calls a tool: its `read_file` returns an image or a
PDF as content only when the model will see it, and otherwise refuses with a text explanation. With
no public answer, raider rebuilt the decision itself as `supports('image_input')` and a
`tool_wire_format` in `anthropic | responses | gemini`. That guess is wrong in several places:

- AKIAnthropic: the image is sent as the placeholder (k359 live probe: the shim drops it), but
  raider believed it would be seen.
- Gemini before the 3 series: no documented form, but `gemini` was on the list.
- Perplexity: images yes, PDFs no (no `input_file` in the Agent API).
- MoonshotAnthropic, LMStudioAnthropic, AKIAnthropic: no `document` block in a `tool_result`, so a
  PDF becomes the placeholder.
- The `anthropic` wire reads a PDF without vision (k371, MiniMax-M2.7), so tying PDFs to
  `image_input` refuses a PDF that would have worked.

## Decision

1. **Two capability flags from two new code-less capability roles** (entries in `%ROLE_TO_CAPS`,
   ADR 0002; roles from day one, ADR 0016 decision 2):
   - `Langertha::Role::ToolResultImages` → `tool_result_images`: *an image a tool returns reaches
     the selected model as an image it sees, in this engine's tool-result wire form*.
   - `Langertha::Role::ToolResultPDF` → `tool_result_pdf`: *a PDF a tool returns reaches the
     selected model as a native document it reads*.

   Without the flag, the content becomes the k336 placeholder. Both flags are model-scoped like
   `image_input` (ADR 0019).
2. **The registry is the single source of truth.** `Role::Tools::format_tool_results` reads
   `supports('tool_result_images')` and `supports('tool_result_pdf')` to choose the form. The
   private `_tool_result_images_on_wire` and `_tool_result_pdf_on_wire` hooks are removed. A caller
   asking `supports()` and the tool loop formatting the result can no longer disagree.
3. **The wire facts close the base `engine_capabilities`**, after the model corrections and the
   learned layer (ADR 0032), so a probed `image_input` flows through. The value object owns them,
   in one table in `Langertha::ToolResult`:
   - `carries_native($fmt, $kind)`: the engine's current `tool_wire_format` has a native form for
     the kind (`image` / `pdf`: `anthropic`, `responses`, `gemini`). Without it the flag is
     dropped, so an engine whose caller switched `tool_wire_format` to a wire without a form makes
     no claim.
   - `native_needs_vision($fmt, $kind)`: the form reaches only a model that sees images. True for
     an image on every wire, and for a PDF on `responses` and `gemini` (k361: OpenAI and Google
     document PDF reading as a vision feature). False for a PDF on `anthropic`, which a text-only
     model reads as extracted text (k371). Where it is true, the flag requires `image_input`.
4. **Per-provider facts stay with the engines:** AKIAnthropic clears `tool_result_images`
   (k359), Gemini grants both flags in layer 3 for Gemini 3 and later only, Perplexity composes
   only the image role, and on the `anthropic` wire `tool_result_pdf` follows
   `_tool_result_source_blocks_on_wire` (cleared in `AnthropicBase`'s `around
   engine_capabilities`). That predicate stays private, because it also governs text `document`
   and `search_result` blocks, which are the caller's own choice and no capability question.
   `format_tool_results` passes `native_pdf` on the `anthropic` wire too (default 1 for a bare
   `ToolResult->to('anthropic')`), so the `document` block also needs the flag.
5. **The manifest does not publish either flag** (`Manifest::Builder` allowlist, classified in
   `t/96_manifest_builder.t`). They describe how Langertha serializes a tool result on the
   engine's own wire. Behind a proxy's public URL, that is the proxy's behavior.

### Engine decisions (checked 2026-10-19)

| Engine (wire) | `tool_result_images` | `tool_result_pdf` | Source |
|---|---|---|---|
| Anthropic (`anthropic`) | with `image_input` (Claude 3+) | yes | https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls (`tool_result` content "can use the `text`, `image`, `document`, or `search_result` types") |
| MiniMaxAnthropic | with `image_input` (MiniMax-M3) | yes (also M2.x, read live k371) | k359, k364, k371 |
| MoonshotAnthropic | with `image_input` (kimi-k3, k2.6, k2.7-code) | no (no `document` block, k364) | k359, k364 |
| LMStudioAnthropic | only with a learned `image_input` (ADR 0032) | no (k366) | k359, k366; not documented by LM Studio |
| AKIAnthropic | no (live probe: the shim drops it, k359) | no (529 on `document`, k364) | k359, k364 |
| OpenAIResponses (`responses`) | with `image_input` | with `image_input` | openai-openapi `FunctionCallOutputItemParam.output`: "array of content outputs (text, image, file)" (`input_text` / `input_image` / `input_file`) |
| Perplexity (`responses`) | with `image_input` | no | https://docs.perplexity.ai/api-reference/agent-post ("an array of input_text and input_image content parts", no `input_file`) |
| Gemini (`gemini`) 3 and later | with `image_input` | with `image_input` | https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/tools/function-calling ("For Gemini 3 and later models, you can include multimodal content (images and PDFs) in `functionResponse`"); https://ai.google.dev/gemini-api/docs/generate-content/function-calling (`functionResponse.parts[].inlineData`, images png/jpeg/webp, documents `application/pdf`; says "Gemini 3 series" only). `gemini-4-argon` is in the supported-models table |
| Gemini before 3 | no | no | same guide: not available before the 3 series |
| OpenAI (chat completions) and every other `openai`-wire engine | no | no | OpenAI spec `ChatCompletionRequestToolMessage`: "For tool messages, only type `text` is supported." See Future work for xAI, Mistral, DeepSeek |
| Ollama (`ollama`), NousResearch / AKI (`hermes`) | no | no | no documented form |

The `anthropic` "yes" for images and every row except the k359/k364/k371 probes is
documentation-derived, not live-verified.

## Rationale

- **Ask the registry, not the wire name.** "Will the model see this image?" depends on the model
  (`image_input`, layer 3, learned layer), the wire (does a form exist), and the provider (does the
  shim honor it). Only core knows all three. A caller that rebuilds the conjunction from public
  pieces gets the provider part wrong, as raider did.
- **Two flags, not one.** Images and PDFs come apart on real engines: Perplexity takes images but
  no PDFs, and MiniMaxAnthropic's text-only M2 models read PDFs but no images. One flag would be
  wrong on one side for each of them.
- **Capability roles, not predicates.** A private predicate is invisible to `supports()`, the
  manifest classification and the registry guards. ADR 0002 already offers the per-engine and
  per-model yes/no, with corrections and a learned layer. A parallel hook system would duplicate
  it.
- **Dependencies in the base, after the learned layer.** Writing `image_input` into every
  layer-3 row a second time would drift, and it would miss a probed fact. The base method is the
  last place every layer has passed through.
- **Wire facts in the value object.** Which wire has a form, and whether that form needs vision,
  is decided by what `ToolResult->to` emits. Keeping the table next to the serializer means a new
  form changes one place, and a test pins the table against the serializer's output.

### Alternatives considered

- **Publish the private predicates as public methods** (`tool_result_images_on_wire`). Rejected:
  the caller would still have to combine them with `image_input` and the wire, and the result
  would not show up in `supports()` / `engine_capabilities`.
- **One flag `tool_result_media`.** Rejected, see Rationale.
- **Gate PDFs on `image_input` everywhere.** Rejected: on the `anthropic` wire it would refuse
  PDFs that MiniMax-M2.x reads today (k371).
- **Add new wire forms (OpenAI chat `role: tool`, Ollama, Hermes) in the same change.** Out of
  scope. No provider documents a form there today (see the table), and "off when in doubt" holds
  (ADR 0038).

## Consequences

- raider can replace `_engine_sees_images` with `supports('tool_result_images')` for images and
  `supports('tool_result_pdf')` for PDFs (follow-up in langertha-raider, noted on karr #380).
- The k344/k359/k361 Updates of ADR 0019 described `image_input` as the flag that selects the
  tool-result form. It now does so through `tool_result_images` / `tool_result_pdf`. The cost those
  Updates name (an over-broad `image_input` claim can put an image part into a tool-loop turn)
  still holds, because of dependency 3.
- Two deliberate behavior changes. Gemini 4 (`gemini-4-argon`) and later now get the native
  forms (the old predicate matched `gemini-3` only). An engine that does not compose the roles
  but was forced onto a native wire by the caller (`Engine::OpenAI->new(tool_wire_format =>
  'responses')`) used to send images natively, because the old hook defaulted to 1; it now sends
  the placeholder. Only engines whose provider decision is recorded above claim a form. The
  reverse case follows the same rule: an Anthropic-family engine forced onto `responses` or
  `gemini` sends a PDF natively for a vision model (main sent the placeholder, the old PDF hook
  defaulted to 0) and the placeholder for a text-only one. Forced wires are pinned in
  `t/78_tool_result_media_capability.t`.
- An engine that wants to claim a tool-result form composes the role and, where it is model-scoped,
  adds layer-3 rows. A flag cleared for want of documentation is added once a provider documents
  the form. Pinned per engine in `t/78_tool_result_media_capability.t`; a flip there is a decision
  change and belongs in the table above.

## Future work

- None of the "yes" rows except the k359/k364/k371 probes is live-verified. A live tool-loop test
  per keyed provider would confirm that the model describes the image or PDF.
- A tool-message image form on the `openai` wire (`role: tool` content with `image_url` parts)
  and native `images` on an `ollama` tool message. xAI's OpenAPI schema allows `image_url` /
  `file` parts in a tool message and says so explicitly; Mistral's `ToolMessage.content` takes
  `ContentChunk[]` including `image_url`, and its tokenizer (v13+) encodes images in tool results;
  DeepSeek's reference allows content parts while its vision guide says "user messages only";
  Ollama's server code keeps tool-message images but does not document them. `ToolResult` has no
  such form today; each needs a live probe before a claim (noted on karr #380).

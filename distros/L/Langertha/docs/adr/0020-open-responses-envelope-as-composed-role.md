# ADR 0020 — The Open-Responses wire envelope is a composed role; divergent parents meet in overridable hooks

- Status: accepted
- Date: 2026-09-10
- Tags: engines, inheritance, roles, composition, wire-format, symmetry, responses, perplexity

## Context

ADR 0016 fixed the rule for *when* a wire envelope earns a `Role::<X>Compatible`: **at the
moment a second consumer needs that envelope while descending from a different parent** — never
ahead of that, never for symmetry alone. It named ADR 0013 (the Anthropic extraction) as the
*outcome* of that trigger, "not a template to be applied ahead of it", and its Consequences
directed that any actual extraction be done "as part of that shim's ticket, following the ADR
0013 shape".

k139 is the first firing of that trigger, and the cleanest example of it in the tree.

Before k139 the Open-Responses wire envelope — `input` instead of `messages`, top-level
`instructions`, flat tool objects, an `output[]` array discriminated by `type`,
`input_tokens`/`output_tokens` usage, the typed-SSE stream — lived inline in
`Engine::OpenAIResponses` (a subclass of `Engine::OpenAI`), exactly as the Anthropic envelope
once lived inline in `Engine::AnthropicBase`. It had one consumer, so ADR 0016 kept it in the
class.

Two facts made k139 fire the trigger:

1. **Perplexity retired its Sonar Chat Completions surface** (EOL 2026-09-27, karr k139). The
   named successor is the **Agent API** (`POST /v1/agent`), which speaks the *same*
   Open-Responses envelope — not `/chat/completions`. So a second consumer of that envelope now
   exists.
2. **That second consumer cannot inherit from the first.** `Engine::OpenAIResponses` reaches
   the envelope through the full OpenAI dialect (`extends OpenAI` → `OpenAIBase` → `Remote`:
   Bearer auth, key, model list, OpenAPI spec). Perplexity's Agent API shares *none* of that
   dialect — it is a lean engine that needs only `Engine::Remote`'s auth+HTTP+JSON and would
   inherit wrong capability flags (embeddings, whisper, `json_object`) and the wrong dispatch if
   it extended `OpenAIBase`. The two consumers descend from **different parents**.

This is the case ADR 0016's decision 1 describes literally but the Anthropic precedent (ADR
0013) never actually exercised: `AnthropicCompatible`'s consumers all share one parent
(`AnthropicBase`), so its extraction could be a byte-identical *pure move*. Here the parents
diverge, so the extraction cannot be a pure move — the envelope has to absorb the divergence
somewhere.

## Decision

Extract the Open-Responses envelope from `Engine::OpenAIResponses` into
**`Langertha::Role::ResponsesCompatible`**, placed symmetrically alongside
`Role::OpenAICompatible` and `Role::AnthropicCompatible` — the third wire-envelope role. The
role owns the envelope body: `chat_request`, `chat_response`, `chat_stream_request`,
`parse_stream_chunk`, `stream_format`, the `output[]` walker, usage normalization
(`input_tokens`/`output_tokens` → `prompt_tokens`/`completion_tokens`), `_parse_function_call`,
`_responses_text_format`, and the wire-format builders (`_build_tool_wire_format` and
`_build_reasoning_wire_format` → `responses`; `chat_operation_id` → `createResponse`).

### Divergence lives in five overridable hooks, not in subclass branching

Because the two consumers descend from different parents, the role carries the OpenAI-Responses
behaviour as the **default**, and factors every point where Perplexity's Agent wire diverges
into one overridable method. Divergence is by-hook, never by `ref($self)` test:

| Hook | OpenAI-Responses default | Perplexity Agent override |
|---|---|---|
| `_responses_model_kwargs` | `model => chat_model` | `preset => …` (the four sonar ids map to fast/low/medium/high) or `model` pass-through |
| `_responses_format_kwargs` | `text => { format => … }` (flat json_schema) | top-level `response_format => …` (Chat-Completions shape) |
| `_responses_dispatch` | OpenAPI operation `createResponse` → `/v1/responses` | direct `POST …/v1/agent` (`generate_http_request`) |
| `_normalize_input_item` | pass `{ role, content }` through | stamp `{ type => 'message', … }` (typed items) |
| `_responses_extra_fields` | none | lift `search_results` → `Response.citations` |

The seam the role does **not** own is authentication: each consumer supplies its own `api_key`
/ `update_request`, so the role never clobbers an inherited key builder. `OpenAIResponses` keeps
OpenAI's Bearer/key/model-list by inheritance; `Perplexity` declares its own Bearer
`update_request` on `LANGERTHA_PERPLEXITY_API_KEY`.

### The two consumers

- **`Engine::OpenAIResponses`** — `extends OpenAI`, `with Role::ResponsesCompatible`. A thin
  shell: inherits the OpenAI dialect, composes the envelope on top, takes all five hook
  defaults, and opts out of streaming (`stream_format => undef` + `around engine_capabilities`
  clears `streaming`). Behaviourally unchanged by the extraction.
- **`Engine::Perplexity`** — `extends Remote` (auth + HTTP + JSON only), composing the
  universal chat roles plus `Role::ResponsesCompatible` via the explicit `-excludes` list (ADR
  0015): `Role::ReasoningEffort => { -excludes => ['_build_reasoning_wire_format'] }` so the
  role's `responses` builder wins, exactly as `AnthropicBase` wires `AnthropicCompatible`. It
  overrides all five hooks and keeps streaming (`stream_format => 'sse'`).

### Capabilities stay honest by composition (ADR 0002)

Perplexity's flag set follows what it composes, with one wire-reality correction. It composes
**no** `Role::Tools` (so `tools_native` / `tool_choice_named` stay off — see the ADR 0005 note
below), **no** `Role::PromptCache` (caching is automatic on the Agent API — no request-side
key), and **does** compose `Role::ReasoningEffort` (`reasoning_effort` on, wire
`reasoning.effort`). The single `around engine_capabilities` correction deletes
`response_format_json_object`, because the Agent API's `response_format` enum is
`json_schema`-only. This replaces the pre-k139 engine that inherited `OpenAIBase`'s flags and
then had to `delete` the ones that were wrong (embeddings, whisper, tool calling) — the lean
composition makes the inventory truthful up front rather than by subtraction.

## Rationale

**Why a role at all, and why now.** ADR 0016's trigger — a second consumer from a different
parent — fired for the first time. Keeping the envelope in `OpenAIResponses` would force
Perplexity to either inherit the whole OpenAI dialect (dishonest capabilities, wrong dispatch)
or re-implement the entire Open-Responses body a second time. The role is the only option that
leaves both consumers speaking one maintained envelope.

**Why its own ADR rather than an amendment to 0016.** 0016 is the *rule*; this is an *instance*
of the rule firing, and 0016 explicitly delegates the recording of an actual extraction to a
"0013-shaped" ADR tied to the shim's ticket. Folding a concrete role plus a new hook pattern
into the policy ADR would conflate the trigger with a firing of it. This ADR is to
`ResponsesCompatible` what 0013 is to `AnthropicCompatible`.

**Why hooks and not a subclass split.** 0013 could be a byte-identical pure move because its
consumers shared a parent; the request-body tests carried it unchanged. Here the parents diverge
on five concrete slots (model vs preset, `text.format` vs top-level `response_format`, OpenAPI
vs direct POST, typed vs pass-through input, extra citation fields). Branching those inside the
role on the concrete class would rebuild the entanglement the role exists to dissolve; an
overridable method per slot keeps the OpenAI path as the readable default and each divergence
named and local. This is the piece of architecture 0013 and 0016 do not describe, and the
reason this decision is worth its own number.

## Consequences

- The Open-Responses envelope is now a composable Moose role mirroring `Role::OpenAICompatible`
  and `Role::AnthropicCompatible`; it is classified as a wire envelope in
  `t/78_capability_registry.t` and catalogued in `Langertha.pm`.
- **Adding a third Open-Responses consumer** = compose `Role::ResponsesCompatible` and override
  only the hooks whose wire slots differ; nothing else is re-implemented. If the new consumer's
  divergence does not fit an existing hook, add a hook (OpenAI default + override), do not branch
  on the class.
- ADR 0016 is confirmed by a live firing, and ADR 0013's shape is confirmed as the template for a
  firing — with the hook layer as the addition demanded by consumers on different parents.
- ADR 0006 is nuanced exactly as 0013 nuanced it: inheritance still encodes the transport root
  (`Remote`); a third dialect envelope now lives on the role axis. Capabilities still derive from
  the composed roles (ADR 0002).
- Perplexity remains the sole exemplar of the ADR 0005 rewrite direction 1 — see the note added
  there.
- **Cross-links:** **ADR 0016** (the trigger this fires — first different-parent firing),
  **ADR 0013** (the precedent envelope role and the shape followed here), **ADR 0006** (dialect
  axis / capability axis this sits on), **ADR 0002** (capabilities by composition — the lean
  Perplexity inventory), **ADR 0005** (direction-1 exemplar preserved), **ADR 0015** (`-excludes`
  canon for the lean composition), **ADR 0001** / **ADR 0009** / **ADR 0010** (`responses`
  `tool_wire_format` / `reasoning_wire_format` and the value-object dispatch the envelope routes
  through), **ADR 0017** (`created_at` via `Moment->from_wire`). `CONTEXT.md` fixes the
  vocabulary (**wire envelope**, **dialect axis**, **capability axis**; the `responses` format).

## Future work

- karr **k147** — the Perplexity Agent API wire is built to the documented Open-Responses shape,
  not yet verified against a live call. Eight wire points are annotated `LIVE-CONFIRM (k139)` in
  `Engine::Perplexity` / `Role::ResponsesCompatible` (typed-input requirement, `response_format`
  slot + `strict`, model→preset mapping and which real model each preset runs, citation
  block/marker shape, retrieve path, typed-SSE framing). A live call (approval-gated) resolves
  them; nothing here blocks on it.

## Update (k212 — one `output[]` walker for the reply and the stream)

The envelope's `output[]` walker is now a single method, `_responses_walk_output`, and both
paths read through it: `chat_response` walks the whole response, and `parse_stream_chunk`
walks the `response` object that the terminal `response.completed` / `response.incomplete`
event carries. A streamed and a non-streamed reply of the same response therefore cannot
disagree about their tool calls (ADR 0003) or thinking. `finish_reason` still differs on a
text-only stream (the final chunk carries none unless it has tool calls — karr k222). Before this, the stream
parser read only text deltas and usage, and streamed function calls were lost — harmless while
`OpenAIResponses` opts out of streaming and Perplexity streams without tools, but a streaming
Responses consumer with function tools (XAIResponses, k206) would have ended its tool loop
silently.

- **Tool calls come from the terminal event only.** The incremental function-call events
  (`response.output_item.added` / `.done`, `response.function_call_arguments.delta` / `.done`)
  are not assembled: the terminal `output[]` is complete and authoritative, and reading only it
  means a call is delivered once, on the `is_final` chunk, where
  `Role::Chat::aggregate_tool_calls` collects it. Text is not re-read from it (it already
  streamed as `output_text.delta`); a reasoning summary is, since no reasoning delta is read.
- **A text-only stream's final chunk is unchanged.** `finish_reason` is set on the final chunk
  only when it carries tool calls (then `tool_calls`), so Perplexity's streams keep the chunks
  they had. No shipped engine streams Responses tool calls yet (Perplexity has no tool calling,
  OpenAIResponses does not stream); XAIResponses (k206) is the first consumer. A stream carrying
  two terminal events would deliver the calls twice — the documented events do not allow that;
  the k206 xAI stream capture must confirm it.
- **`response.failed` and `error` fail the stream.** Both are terminal and carry no reply, so
  `parse_stream_chunk` croaks with the provider's error code and message (the LMStudio parser's
  pattern), which fails the `chat_stream_realtime_f` future on every backend (ADR 0027) instead of
  ending the stream as an empty success.

The event names and shapes are from OpenAI's streaming-events reference (fetched 2026-09-25);
no real SSE capture of a Responses tool-call stream exists yet, and xAI's event names wait on the
k206 capture. Test: `t/43_responses_stream_tool_calls.t` (the stream is built from the documented
events around the verbatim non-streaming capture `responses_web_search_function_call.json`).

## Update (k206 — server tools, citations merge, `max_output_tokens` gate in the shared envelope)

Three envelope-level changes from ADR 0030. (1) Both body builders run the `tools` kwarg through
one per-item step (`_responses_tools_kwarg`), which also appends the engine's `server_tools`
(validated; a request tool of the same kind replaces a default) and routes a server tool
through `Langertha::ServerTool` and the engine hook `_server_tool_wire_check` — a sixth,
capability-scoped divergence point in the same shape as the five. (2) A `citations` key from `_responses_extra_fields` no longer passes through
blindly: `_responses_merge_citations` merges it with the answer's `url_citation` annotations
(hook first, one entry per page); with no annotations the hook's list is returned unchanged, so
Perplexity is unaffected. (3) `max_output_tokens` is sent only when
`supports('response_size')` (a no-op for the shipped consumers). The output walker also croaks
on a client-actionable item it does not map, on the reply and on the stream's final chunk.

## Update (k222 — the stream's final chunk carries the walker's `finish_reason`, text-only too)

The k212 bullet "a text-only stream's final chunk is unchanged" no longer holds, deliberately: the
final chunk of a Responses stream now carries whatever `finish_reason` the one walker reads off
the terminal `response` object — `tool_calls` with function calls, `stop` for a completed
message, the message status (`incomplete`) for a truncated one — so the streamed and the
non-streamed reply of the same response also agree on it. That matches the other dialects,
whose streams already end on a chunk carrying the provider's finish reason. The only field that
changes is `finish_reason`, and only on the final chunk; for Perplexity's text-only streams it is
additive (`stop` where there was none; golden `t/data/stream_text_only_golden.json` regenerated,
diff = that one key on the final chunk of each read path). A terminal event whose `output[]` has
no message item still yields no `finish_reason`, on the stream and on `chat_response` alike.
Tests: `t/43_responses_stream_tool_calls.t`, `t/43_stream_text_only_pin.t`.

## Update (k213 — Perplexity gains client function tools; a sixth envelope hook filters the tool-loop echo)

The Agent API takes client-executed `type:function` tools (advisor 2026-09-25, docs only: the
OpenAPI for `POST /v1/agent` and the custom-functions guide; no live capture yet). Perplexity now
composes `Role::Tools`, with `-excludes => ['_build_tool_wire_format']` so the envelope's
`responses` builder wins (ADR 0015, as for `reasoning_wire_format`). Three envelope changes
follow, none of them per-format code on the engine (ADR 0001):

- **`_responses_echo_item($item)` — a sixth hook on the envelope role.** The five hooks of the
  Decision plus this one live on `Role::ResponsesCompatible`; `_server_tool_wire_check` (k206
  Update) is the capability-scoped one on `Role::ServerTools`. `Role::Tools::format_tool_results`
  (`responses` branch) runs every echoed `output[]` item through it after hoisting nested
  function calls. The default passes the item through (OpenAI takes its own output items back).
  Perplexity's Agent input is a closed oneOf — `message` | `function_call` |
  `function_call_output`, message parts only `input_text` / `input_image` — so its override keeps
  function calls verbatim (`thought_signature` included, as Perplexity's own sample replays
  them), flattens an assistant message to `{type:message, role:assistant, content:<text>}`, and
  drops every other item (`search_results`, `*_results`, `mcp_*`). Presets merge their
  `web_search` with the caller's tools, so the filter is needed on the first tool turn. The hook
  sits at the echo rather than in `_normalize_input_item` because the echo is where output items
  become input, for `chat_with_tools_f` and for any caller of `format_tool_results`
  (langertha-raider) alike.
- **`tool_choice` only where the engine supports its kind.** `_responses_tool_choice_kwarg`
  (both body builders) sends a choice only when `supports('tool_choice_<kind>')` (`named` for a
  specific tool); otherwise it is dropped, silently for `auto` (the default), with a carp for
  anything else. Perplexity clears all four `tool_choice_*` flags (the Agent schema has no such
  field), so it never sends one; OpenAIResponses keeps all four and is unchanged.
- **`parallel_tool_calls` only where `supports('parallel_tool_use')`.** `Role::Tools` brings
  `Role::ParallelToolUse`; Perplexity clears the flag (no such field), OpenAIResponses keeps it.

Streaming with tools is unchanged beyond k212/k222. Perplexity's built-in tools (`web_search`,
`fetch_url`, `sandbox`, `people_search`, `finance_search`, `mcp`) are not modelled: that is
k206 Phase 2, which will reuse this echo filter. Tests: `t/68_perplexity_function_tools.t`
(documented shapes; request building, `chat_f`, the echo filter, and `chat_with_tools_f` end to
end over the mocked transport).

## Update (k233 — an unsendable `none` withholds the tools; an unreadable choice drops where there is no field)

Two edge cases of the k213 `tool_choice` rule, both in `_responses_tool_choice_kwarg` (shared by
both body builders, which now run it *after* `_responses_tools_kwarg`):

- **`tool_choice => 'none'` the engine cannot send withholds the request's tools.** Dropping
  only the field (k213) left the tools on the wire with no restriction, so the model could call a
  tool the caller ruled out. The caller's intent is honored instead by leaving `tools` out of the
  body (and with it `parallel_tool_calls`), with a carp saying so. Every tool goes: function
  tools, native built-in hashes and the engine's `server_tools` defaults alike — `none` rules out
  any tool call, and ADR 0030 does not make server tools independent of `tool_choice`. A
  Perplexity preset still runs its own `web_search`; that is the preset, not a request tool, and
  out of the client's reach. Only Perplexity hits this today (OpenAIResponses sends `none`).
- **A choice `ToolChoice->from_hash` cannot read** (a provider-native one such as
  `{type: web_search_preview}`) still passes through verbatim where the engine supports any
  `tool_choice_*` kind — the provider judges (ADR 0001 k227). On an engine with no `tool_choice`
  field at all (all four flags cleared: Perplexity) it is dropped with a carp, since sending it is
  a certain 400.

`ToolChoice->to_perplexity` (the old Sonar `/chat/completions` string forms) stays public, now
documented as legacy; the Agent API has no `tool_choice`. Tests: `t/68_perplexity_function_tools.t`.

## Update (k239 — the tool_choice rule moved to Role::Chat)

The k213/k233 `tool_choice` rule is no longer Responses-only: it is
`Role::Chat::_gate_tool_choice`, which `_responses_tool_choice_kwarg` now calls before it
serializes with `to('responses')`, as do the OpenAI-compatible, Ollama native and LM Studio
native builders (ADR 0002 k239 Update). One behavior differs on this envelope: an undefined
`tool_choice` is deleted where the engine claims no `tool_choice_*` (Perplexity) instead of going
out as `null`. `_responses_parallel_tool_calls_kwarg` calls the shared
`_parallel_tool_calls_kwarg`, which adds a carp when a set `parallel_tool_use` is dropped (k241).

## Update (k232 — the Perplexity function-tool shapes are live-verified)

This update revises two statements in the k213 Update: "docs only … no live capture yet" and the
test note "documented shapes". The maintainer approved six live calls, made on 2026-09-29 (UTC,
per the captured `Date` headers) with preset `fast` and `max_output_tokens` 300. All six returned
HTTP 200. The wire matched the k213 implementation, and no code changed.

1. **The function_call turn.** The call is a top-level `output[]` item
   `{type: function_call, id: fc_<uuid>, call_id, name, arguments: <JSON string>, status: completed}`.
   It has no `thought_signature`, and no search ran.
2. **The echo turn with `id` and `status`.** Sending the call item back with its `id` and `status`
   intact, followed by the `function_call_output`, is accepted.
3. **The echo without tools.** The same input with no `tools` in the request is also accepted. This
   answers the k233 question: withholding the tools for an unsendable `none` leaves a valid body,
   even with earlier `function_call` / `function_call_output` items in the input. The preset then
   ran its own `web_search`.
4. **The streamed call turn.** `response.output_item.added` and `.done` each carry the whole call,
   and there are no argument-delta events. The call appears once in `response.completed`'s
   `output[]`. The stream yields one tool call, not three.
5. **Search plus a function tool.** In one sample, the preset searched and answered in text without
   calling the function.
6. **The filtered mixed echo.** The input had `search_results` dropped and the assistant preamble
   flattened to string `content`, as `_responses_echo_item` does, and it was accepted. This turn
   was *constructed*: the live call confirms only that the filtered echo gets a 200. The claim that
   the Agent API rejects the *unfiltered* items (the reason for the hook) is still
   documentation-derived.

The preset `fast` now resolves to `openai/gpt-6-luna` (it was `gpt-5.6-luna` mid-September). A side
finding: Perplexity sends unsuffixed `x-ratelimit-limit` / `-remaining` / `-reset` (epoch seconds) /
`-used` headers. `Engine::Remote` does not parse them, so `rate_limit` stays undef on success (karr
#356). The 18 verbatim capture files are `t/data/perplexity_agent_{function_call,function_call_echo,
function_call_echo_notools,function_call_stream,search_function_call,mixed_echo}.*`. Each
`.request.json` holds the body Langertha built, with no key or auth header.
`t/68_perplexity_function_tools.t` replays them, checking the exact request bodies, the reply
reading, `chat_with_tools_f` end to end, and the stream.

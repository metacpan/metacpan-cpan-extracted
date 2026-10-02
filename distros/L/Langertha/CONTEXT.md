# Langertha — Domain Context

Domain language for Langertha's LLM engine framework. This file records the
canonical terms for the tool-calling wire-translation area, sharpened during
architecture review. It complements `CLAUDE.md` (which describes structure) by
fixing the vocabulary for the value objects and the format seam.

## Language

### Tool wire-translation

**tool_wire_format**:
The single per-engine enum naming which tool dialect an engine speaks —
`openai` | `anthropic` | `gemini` | `ollama` | `responses` | `hermes`. The one
authority from which all per-format tool behaviour (outbound, inbound, results,
final-text) derives.
_Avoid_: "provider format", "tool dialect", "format flag"

**Tool**:
The canonical, immutable tool *definition* (name, description, input_schema).
Owns outbound serialization via `to($fmt)` and inbound construction via
`from_$fmt`.
_Avoid_: "tool spec", "function definition"

**ToolCall**:
The canonical tool *invocation* emitted by a model (name, arguments, id,
synthetic). Owns inbound parsing via `extract($fmt, $data)` (locate + parse) and
serialization via `to($fmt)`.
_Avoid_: "function call", "invocation hash"

**ToolResult**:
The canonical *result* of executing one tool (name, call id, content, isError).
Serializes one result *block* via `to($fmt)`. Does NOT own the surrounding
message envelope.
_Avoid_: "tool output", "tool response"

**ToolChoice**:
The canonical tool-selection *policy* (none/auto/required/named). Serializes via
the same unified `to($fmt)` dispatch as the other value objects, over its
per-format serializers — keyed by `tool_wire_format`, for the wires that carry a
tool_choice parameter (openai/anthropic/gemini/responses). The original exemplar
of the value-object pattern the others now follow.
_Avoid_: "tool_choice hash"

**ServerTool**:
A tool the *provider* runs during the request (web search, file search, remote
MCP, ...), as `Langertha::ServerTool`: the provider-native hash, pinned to one
`tool_wire_format` and never translated — `to($fmt)` croaks off its wire.
Recognized by `Tool->classify` (`server`). Not a **Tool**: a Tool is a function
the client runs. **ADR 0030**.
_Avoid_: "built-in tool" (built-ins include client-executed ones), "hosted
function"

**Server tool call**:
What the provider reports it ran for a ServerTool (`web_search_call`,
`mcp_call`, ...), recorded as `Langertha::ServerToolCall` on
`Response.server_tool_calls`. Never a **ToolCall**: `tool_calls` lists only
calls the client must act on. It travels back unchanged in the **assistant
echo**.
_Avoid_: "server-side ToolCall"

**Result envelope**:
The provider-shaped *conversation elements* wrapping ToolResults for the next
turn — arity differs (OpenAI/Ollama: N `role:tool` messages; Anthropic/Gemini:
one message, N blocks; Responses: N `function_call_output` items) and it always
includes the **assistant echo**. Assembled by thin tag-driven orchestration
(`Role::Tools::format_tool_results`), not by ToolResult.
**Always a LIST, for every `tool_wire_format`** — all three tool loops
(`Chat::simple_chat_with_tools`, its `_f` sibling, `Role::Tools::chat_with_tools_f`,
plus `Raider`) append it with `push @$conversation, ...`, so an arrayref return
lands as one bogus conversation element and the next turn dies walking it
(karr #85). Not every element is a chat *message*: Responses appends `input`
items discriminated by `type`, with no `role` at all.
_Avoid_: "tool result message", "result wrapper", "the result arrayref"

**Assistant echo**:
The re-emission of the prior assistant turn (its text + tool_calls) that must
precede ToolResults so the provider has context. Rebuildable from canonical
ToolCalls + text rather than from raw response data. Not optional on any wire:
the Responses API rejects a `function_call_output` whose `call_id` was not
announced by a preceding **top-level** `function_call` item, which is why the
`responses` envelope hoists a call out of the legacy nested-inside-a-message
shape that `ToolCall->locate` also walks.
_Avoid_: "assistant replay", "history echo"

### Request-side controls (sibling seams)

The same value-object-per-wire-format pattern governs three sibling seams outside
tool-calling. Their canonical vocabulary lives in **ADR 0009** and **ADR 0012**
(not restated here); named only so the parallel is explicit:

**reasoning_wire_format** / **Langertha::Reasoning**:
The per-engine reasoning dialect (`openai` | `anthropic` | `gemini` | `responses`)
and the value object that clamps + places `reasoning_effort` onto it. Deliberately
separate from `tool_wire_format` — engines sharing one tool dialect diverge on
reasoning (DeepSeek/MiniMax/Groq are all `tool_wire_format=openai`).

**cache_wire_format** / **Langertha::PromptCache**:
The per-engine prompt-cache dialect — Anthropic `cache_control` (enable breakpoint)
vs OpenAI `prompt_cache_key` (routing hint); the two are asymmetric and carry
distinct capability flags.

**knob_wire_format** / **Langertha::Runtime::Knobs**:
The per-engine self-hosted runtime-knob dialect — `vllm` | `sglang` | `llamacpp` —
and the value object that clamps + places the prefix-cache isolation/reuse knobs
(`prefix_cache_salt`, `cache_prompt`, `n_cache_reuse`, `id_slot`, `priority`,
`return_cached_tokens_details`, `extra_key`) onto it. **No shared default:** an
`openai` knob dialect does not exist (the OpenAI cloud API has no such knobs), so
an engine that composes the role must set its tag explicitly or die at first use.
The three engines share `tool_wire_format=openai` yet accept disjoint knob field
sets — the knob dialect is a distinct concern from reasoning and caching. The
`prefix_caching` capability means *the wire accepts the controls*, not that the
server has caching enabled.

### Request-side generation parameters (the per-dialect block)

**generation-parameter block**:
The slab of per-request body fields (`temperature`, `response_format`,
`response_size`/`max_tokens`, `seed`, `reasoning_kwargs`, `prompt_cache_kwargs`,
`parallel_tool_use`) that a dialect role assembles inline in its own
`chat_request` / `chat_stream_request`, in the same "per-request control beats
engine attribute" ternary shape. `Role::OpenAICompatible` and
`Role::AnthropicCompatible` each carry their own copy — the duplication is a
**deliberate dialect split**, not a missing refactor, because the surrounding
dialect-aware blocks (Anthropic's `response_format` translation to a synthetic
tool, `tool_choice` ↔ `parallel_tool_use` folding, `inference_geo`,
`anthropic-version`) need the wire envelope in scope. → **ADR 0015**.
_Avoid_: "RuntimeKnobs", "the knobs", "knob block" for this pattern — *knob* is
taken by the unrelated self-hosted seam above (`Langertha::Role::RuntimeKnobs`,
`knob_wire_format`, `Langertha::Runtime::Knobs`), whose real `knobs_kwargs_for`
is itself just one line *inside* the generation-parameter block in
`Role::OpenAICompatible::chat_request`. The block is an inline code pattern —
not a role, not a value object, not a wire-format tag.

**generation_kwargs_for** (helper on `Langertha::Engine::Remote`):
The canonical home for the wire-agnostic slice of the generation-parameter
block — a method on the common ancestor that both `Role::OpenAICompatible`
and `Role::AnthropicCompatible` call from their `chat_request` /
`chat_stream_request`. Helper-on-Remote (not a role) because both
consumers descend from `Engine::Remote`, so ADR 0016's second-consumer
trigger does not fire. karr #98; ADR 0015 decision 3.

### Response-side observability (sibling seams)

Two sibling seams sit on the response side. Their canonical vocabularies
live in the ADRs (not restated here); named only so the parallels are
explicit:

**Langertha::Response.timing** (HashRef) — **ADR 0011**:
The response-side timing surface. Holds two classes of keys:
- *engine-agnostic* (standard): `ttft_seconds`, `total_seconds` — Float,
  seconds. `ttft_seconds` only meaningful for async streaming (LWP
  sync streaming buffers the body and cannot observe it).
- *engine-native* (optional, engine-populated): provider-reported stage
  durations, in the *same* flat HashRef — Ollama `load_seconds`/
  `prompt_eval_seconds`/`eval_seconds`, AKI `compute_seconds`, each
  alongside its own `total_seconds`.
  The **`_seconds` suffix is reserved and unit-bearing**: every key
  ending in it is a Float in seconds, engine-agnostic and engine-native
  alike, and an engine reporting a stage timing emits it under that
  suffix (converting if its wire uses another unit). `*_duration` is
  **not** a parallel convention — it is Ollama's back-compat legacy in
  nanoseconds, and no new engine adds one. Native keys share one flat
  namespace with no per-engine prefix, so the suffix is the only thing
  keeping a stem two engines both claim (`total_*`) unit-compatible;
  that hazard is the subject of the ADR 0011 Update (karr k126).

**_merge_timing_field** (Role::Chat private):
First-write-wins merge primitive. Provider-supplied keys (e.g. Ollama
server-reported `total_seconds`) trump client-measured values
(`Time::HiRes tv_interval` around the request). Rationale: server time
excludes network jitter, which is what model-latency dashboards want.
Round-trip latency is recoverable from the difference between
provider-native and client-measured `total_seconds` when both are
present.

**Langertha::Moment** — **ADR 0017**:
The instant a provider reports, currently only
`Langertha::Response.created`. A `Time::Moment` subclass carrying an
overload set: `0+` is the Unix epoch (the back-compat contract, and the
form `to_hash` / `TO_JSON` emit), `""` is the full ISO-8601 stamp with
sub-seconds. The provider's native form stays under `raw` — the same
normalized-plus-native split as `timing` (ADR 0011).
**from_wire** is its one lenient inbound door: epoch number, RFC3339
string or an existing moment in, a `Langertha::Moment` or `undef` out,
never a die — an unreadable stamp drops the field rather than failing
the response. The parse lives in the value object, not in the engine
(ADR 0001's inbound half).

**runtime_metrics** capability — **ADR 0014**:
The self-hosted observability seam. Engines that serve a Prometheus
`GET /metrics` endpoint (vLLM, SGLang, llama.cpp's built-in server)
compose `Langertha::Role::Runtime::MetricsPoll` and advertise the
`runtime_metrics` capability flag via `engine_capabilities`. The
role's `poll_metrics_f` (async, IO::Async) and sync `poll_metrics`
scrape the endpoint and return parsed
`Langertha::Runtime::Metrics` records; the URL is derived
mechanically by stripping the trailing `/v1` from the engine's
`url`. Ollama is intentionally not composed — its runtime stats
live at `/api/ps` in JSON, not at `/metrics` in Prometheus text.
The asymmetry between chat-shape flags (request body fields) and
the observability-shape flag (`runtime_metrics`) is documented in
ADR 0014.

### Engine composition axes

**wire envelope**:
The dialect body of an engine — the `chat_request` / `chat_response` pair, the
auth hook (`update_request`), the stream framing (`stream_format` /
`parse_stream_chunk`), the rate-limit reader. Envelope-shaped and
all-or-nothing: an engine speaks exactly one.
_Avoid_: "wire format" (that is the `*_wire_format` tag), "transport" (that is
`Engine::Remote` + `Role::HTTP`)

**dialect axis**:
The inheritance axis. A **wire envelope** lives on it — in the engine class, or
in a `Role::<X>Compatible` once a second consumer needs it from a different
parent. → **ADR 0006**, **ADR 0013**, **ADR 0016**.
_Avoid_: "the base-class axis" when the envelope has already moved to a role

**capability axis**:
The role axis. A **capability** — a separable feature surface with its own
attributes and/or lifecycle methods (`Role::CachedContent`, `Role::Embedding`,
`Role::Runtime::MetricsPoll`) — lives on it from day one, single consumer or
not, because `engine_capabilities` derives from `does($role)`. → **ADR 0002**,
**ADR 0016**.
_Avoid_: counting consumers to decide the axis — consumer count is the trigger
for moving an *envelope*, never for placing a *capability*

**model_capability_corrections** (the per-model correction layer):
Layer 3 of `engine_capabilities`. A declarative, ordered list of
`( $matcher => \%overrides )` pairs an engine returns to refine the
role-derived base for the currently selected `chat_model` — `$matcher` is an
exact model id (`eq`) or a `qr//` family regex, `\%overrides` maps a capability
flag to `1` (assert) or `0` (clear), later matching entries win. The home for a
wire reality that differs **per model** (`kimi-k3` forbids a forced named tool
while its `kimi-k2.*` siblings allow it). Distinct from the engine-**wide**
correction — `around engine_capabilities`, layer 2, the endpoint gate — which
runs outside the base method and so is the last word. → **ADR 0019**, **ADR 0002**.
_Avoid_: "capability override" (ambiguous — say which layer), "the `around` for
a model" (the whole point is that per-model reality does *not* go in the `around`)

**model_capability_exclusions** (the per-model pairwise-exclusion seam):
The sibling of `model_capability_corrections`, one layer up — at the
`chat_f` / `chat_stream_realtime_f` level, not inside `engine_capabilities`. A
declarative, ordered list of `( $matcher => $rule )` pairs keyed on `chat_model`
(same matcher grammar: exact id `eq`, or a `qr//` family regex). The difference
is the payload: a **coderef**, not a `{ cap => 0|1 }` hash — because it expresses
a *relationship between two* request fields (combining `tools` with a
structured-output `response_format` in one body) that a boolean flag cannot
spell, and the rule croaks on the combination its model rejects with an opaque
400. The conflict is a property of the serving **stack**, not of the model:
Groq and Cerebras reject `tools` + a structured-output `response_format` across
every model they serve (each declaring its own all-models `qr//` rule), while AKI
serves `gpt-oss-120b` + `tools` + a `json_schema` `response_format` at HTTP 200.
So the rule lives **on the affected engines**; there is no shared wire-dialect-base
rule — the earlier `Engine::OpenAIBase` `gpt-oss` rule was removed (2026-09-19,
karr #184 Option C) as a false-positive on the AKIOpenAI / TSystems defaults and
the aggregator routes, which now send both fields on the wire. SGLang declares
an all-models rule for a *forced* `tool_choice` (`required` / named) with a
constraining `response_format`; rules receive `tool_choice_forced` for that
(k245). An engine that constrains nothing composes no rule.
→ **ADR 0024**, **ADR 0021**, **ADR 0019**.
_Avoid_: "capability_exclusions DSL" (the payload is a coderef, deliberately not
a declarative constraint language); "the exclusion capability" (it is not a flag)

## Relationships

- An engine declares exactly one **tool_wire_format**; its default follows the
  wire-envelope roles (`Role::OpenAICompatible`→`openai`,
  `Role::AnthropicCompatible`→`anthropic`, … — see ADR 0013), composed by thin engine bases.
- **tool_wire_format** keys the dispatch into **Tool**, **ToolCall**, and
  **ToolResult** class methods — no per-engine tool methods remain.
- A **ToolResult** serializes to one block; the **Result envelope** assembles N
  blocks plus the **Assistant echo** into provider-shaped messages.
- `hermes` is a **tool_wire_format** value like any other — its outbound is
  prompt-injection and its inbound is `<tool_call>` text parsing, selected by the
  same tag. `Role::HermesTools` is **not** retired by that: the *behaviour* moved
  out into the tag-driven defaults of `Role::Tools`, and the role stays as the
  configuration carrier those defaults read — the call/response tag names, the
  prompt template, and the overridable `hermes_extract_content` for engines whose
  response shape is not OpenAI's. It is also the `does()` source of the
  `tools_hermes` capability flag (ADR 0002), so composing it is how an engine
  advertises the path at all.

## Example dialogue

> **Dev:** "When Anthropic returns tool calls, which module parses them?"
> **Maintainer:** "`ToolCall->extract('anthropic', $data)` — the engine carries
> no parsing method, just `tool_wire_format => 'anthropic'`. The tag picks the
> locator and `from_anthropic`."
> **Dev:** "And feeding results back?"
> **Maintainer:** "Each result is a **ToolResult**; `to('anthropic')` gives one
> `tool_result` block. The **Result envelope** wraps them into a single
> `role:user` message and prepends the **Assistant echo**."

## Flagged ambiguities

- "format_tools" historically meant *both* the outbound serializer *and* the
  engine seam. Resolved: outbound serialization is **Tool->to($fmt)**; the engine
  no longer has a `format_tools` method.
- "tool call" was used for both the model's emitted invocation and the
  execution result. Resolved: **ToolCall** (emitted) vs **ToolResult** (executed)
  are distinct.

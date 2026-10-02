# ADR 0005 — Structured output and forced tool calling are one mechanism; `chat_f` auto-rewrites between forms per capability

- Status: accepted
- Date: 2026-06-26
- Tags: tools, structured-output, chat_f, response-format, rewrite

## Context

A caller can ask for schema-shaped output three ways:

- `tools` — let the model choose to call a tool,
- a forced named `tool_choice` (`{type => 'tool', name => 'extract'}`) — make the
  model emit one specific tool call, i.e. extract a known schema,
- `response_format` (`json_object` / `json_schema`) — structured output with no tool.

On the wire the providers support *different subsets* of these. OpenAI does all three
natively. Anthropic does tools and named forcing but has **no native `response_format`**.
Perplexity does **no tool calling at all** but has native `response_format=json_schema`.
Gemini routes structured output through `generationConfig.responseSchema`, Ollama through
`format`.

Underneath, the three intents are the same capability: *schema-constrained generation*. A
forced named tool **is** structured output — the tool's `input_schema` constrains the
output. A `response_format` json_schema **is** a tool with no execution. They are
inter-convertible.

If each engine exposed only its native subset, the caller would have to know, per provider,
which of the three forms to send — and an "extract this JSON" request would simply fail on
Anthropic (no `response_format`) or on Perplexity (no tools). ADR 0001 removed per-format
*serialization* from the engines; this decision removes per-provider *form selection* from
the caller.

## Decision

Treat structured output and forced tool calling as two faces of one mechanism, and have the
engine layer **auto-rewrite between the forms in whichever direction the wire reality
requires**, keying the decision off `supports()` (ADR 0002). Two rewrite directions exist
today; native paths are left untouched.

1. **Forced named tool → `response_format`** (`Langertha::Role::Chat::chat_f`,
   `lib/Langertha/Role/Chat.pm:370-398`). When a caller forces a named tool on an engine
   that cannot do named-tool-forcing but can do json_schema
   (`!supports('tool_choice_named') && supports('response_format_json_schema')` —
   Perplexity), `chat_f` deletes `tools` + `tool_choice`, sets
   `response_format => { type => 'json_schema', json_schema => { %{ $tool->to_json_schema }, strict => true } }`,
   loose-parses the returned content (`decode_loose_json`), and attaches a `synthetic`
   `Langertha::ToolCall` carrying the parsed arguments.
   (Post-k139 Perplexity speaks the Agent API — the Open-Responses envelope, ADR 0020 — but
   still advertises `response_format_json_schema` and not `tool_choice_named`, so this direction
   still fires and Perplexity remains its only exemplar in the tree.)

2. **`response_format` → synthetic tool + forced choice**
   (`Langertha::Engine::AnthropicBase::_translate_response_format`,
   `lib/Langertha/Engine/AnthropicBase.pm:176-208`). When a caller asks for
   `response_format` on an engine with no native `response_format` but native forced tools
   (Anthropic), the engine synthesizes a tool from the schema (`Tool->to_anthropic`), forces
   `tool_choice` to it, and `chat_response` lifts the resulting `tool_use` input back into
   `Response.content` as JSON (`AnthropicBase.pm:244-246`).

3. **Both directions converge on the same output shape.** Every rewritten case lands a
   `Langertha::ToolCall` on `Response.tool_calls` (ADR 0003) and/or surfaces the structured
   payload as `Response.content` JSON, so the caller reads the result identically regardless
   of which way the rewrite went — or whether it happened at all.

4. **Native stays native.** The rewrite fires only on a capability gap. OpenAI forwards
   `response_format` verbatim; Gemini emits `responseSchema`; Ollama emits `format`. The
   capability registry (ADR 0002) is what decides *whether* a rewrite is needed.

## Rationale

The caller expresses the intent once and gets the same result shape on every provider. The
per-provider knowledge — "does this engine do `response_format`, or only forced tools, or
neither" — lives in the engine plus the capability registry, never in user code. Because a
tool definition and a json_schema `response_format` are inter-convertible, the framework
*converts* rather than refusing the request.

This is a distinct decision from its siblings: ADR 0001 says the value objects own per-format
*serialization*; ADR 0002 says capabilities are derived and queryable; ADR 0003 says
`Response.tool_calls` is the single *sink*. ADR 0005 is the decision in between — that the
engine layer will *rewrite one intent into another* to close a capability gap, treating
structured output and forced tool calling as one schema-constrained-generation mechanism.

## Consequences

- A new provider with a novel capability gap is handled by adding a rewrite branch keyed on
  `supports()`, not by adding a caller-facing API or a new `Response` field.
- The two rewrite sites sit at deliberately different layers: the forced-tool→`response_format`
  rewrite is in `chat_f` because it is engine-agnostic (any tools-less + json_schema engine
  benefits); the `response_format`→synthetic-tool rewrite is inside `AnthropicBase` because it
  is wire-specific to the Anthropic messages shape. They are not folded into one site because
  they apply at different scopes.
- The full decision matrix (what the caller passed × engine capabilities × resulting wire
  form) is documented in `README.md` ("Tool & Structured-Output Flow"); this ADR records the
  *why*, the README the *what*.
- Cross-links: ADR 0001 (the value objects — `Tool->to_json_schema`, `Tool->to_anthropic`,
  `ToolChoice` — perform the per-format serialization each rewrite invokes), ADR 0002
  (`supports()` gates every rewrite), ADR 0003 (the synthetic `ToolCall` is where every path
  lands). `CONTEXT.md` fixes the vocabulary (**ToolCall**, `synthetic`, **tool_wire_format**).

## Update (k133 — first-party Anthropic gained native structured output)

Decision 2 assumed the Anthropic Messages API has **no native `response_format`**, so the only
way to honor a `response_format` on that wire was to synthesize a tool and force `tool_choice`
onto it. That is no longer true for the **first-party Claude API**: the Messages API now has
native structured output via **`output_config.format`** (`{ type => 'json_schema', schema =>
{...} }`, GA, no beta header). Decision 2's synth-tool rewrite is therefore **superseded for
`Engine::Anthropic`** and **kept, unchanged, for the legacy `/anthropic` shim engines**
(MiniMaxAnthropic, MoonshotAnthropic, AKIAnthropic, LMStudioAnthropic), whose shim endpoints do
not carry the field.

- **The split is a one-method opt-in.** `Role::AnthropicCompatible::_native_structured_output`
  defaults to `0` (shims keep the rewrite); `Engine::Anthropic` overrides it to `1`. On the
  native branch `_take_response_format` pulls the `response_format` off the per-request
  controls / `%extra` / engine attribute (the Messages API 400s if one reaches the wire),
  `_response_format_to_output_config` turns it into the `output_config.format` value (a bare
  `json_object` maps onto an open-object `json_schema`), and the content JSON rides back on the
  wire verbatim — no `chat_response` tool_use lift. On the shim branch
  `_translate_response_format` is exactly Decision 2, untouched.
- **Native structured output streams; the shim rewrite still cannot.** The synth-tool rewrite
  has no streaming counterpart to `chat_response`'s tool_use lift, so `chat_stream_request`
  croaks loudly on a shim rather than streaming unstructured text or leaking `response_format`
  onto the wire (karr #52). The native branch streams the JSON as ordinary text deltas.
- **Decision 1 (Perplexity: forced named tool → `response_format`) is unchanged and still
  valid.** Only Decision 2's Anthropic direction is nuanced.
- **The unify-and-rewrite core is reinforced, not overturned.** Decision 4 said *native stays
  native; the rewrite fires only on a capability gap*. First-party Anthropic simply graduated
  from the gap branch to the native branch — exactly the case Decision 4 anticipated. The same
  mechanism now runs the other way too: `claude-fable-5-1` / `claude-mythos-5-1` **reject**
  forced tool use (`tool_choice` `any` / `tool` → 400), so `Engine::Anthropic`'s
  `model_capability_corrections` clears their `tool_choice_named` / `tool_choice_any` flags and
  `chat_f`'s auto-rewrite routes a forced named tool *through the native structured-output path*
  on those models. Per-model wire truth lives in `model_capability_corrections`, not in `around
  engine_capabilities` — see **ADR 0019** (the ADR 0002 amendment, k138).
- **`output_config` is now shared by two request-side concerns.** `Langertha::Reasoning`
  already places reasoning effort under `output_config.effort` (ADR 0009); structured output
  now places its schema under `output_config.format`. A naive second `output_config` would
  silently drop one, so `Role::AnthropicCompatible::_merge_output_config_format` folds `format`
  into the existing hash — a **merge, not last-writer-wins**. This is a new kind of overlap for
  the ADR 0009 quartet (each concern used to own a disjoint body key); see the ADR 0009 Update.
- **`Tool->to_anthropic` now emits top-level `strict: true` for closed schemas**
  (`additionalProperties:false` + a non-empty `required`), keyed on the schema *shape* and so
  engine-agnostic — a value-object serialization extension in the spirit of ADR 0001 (the value
  object owns its wire shape). See the ADR 0001 strict-tool-use note.

This is an amendment in place, not a superseding ADR: the mechanism ADR 0005 records —
structured output and forced tool calling are one schema-constrained-generation mechanism, and
the engine layer rewrites between forms on a capability gap — stands entirely. One wire grew a
native capability, moving one engine from the rewrite branch to the native branch, which is the
behavior Decision 4 already specified. Contrast ADR 0006 → ADR 0013, where the thing itself
moved axes and a new number was right.

## Update (k182 — first-party Anthropic `json_object` routing corrects the k133 Update)

The k133 Update above described the first-party native branch as: `_response_format_to_output_config`
turns the `response_format` into `output_config.format`, and *"a bare `json_object` maps onto an
open-object `json_schema`."* **That last clause was wrong — it was the bug.** The first-party
`output_config.format` validator **rejects an open schema** (it requires `additionalProperties:false`
on every object), so an open-object stand-in 400s. Live-confirmed and fixed in k182/k149. The
corrected reality on `Role::AnthropicCompatible` (line refs against the integrated tree):

- **A `json_schema` goes native, but its schema is normalized CLOSED first.** `_rf_is_native_schema`
  (`AnthropicCompatible.pm:293`) is the gate — true only for a `json_schema` carrying an actual
  `schema` object. `_response_format_to_output_config` (`:307`) then runs that schema through
  `_close_schema` (`:323`), which recursively sets `additionalProperties:false` on every object
  (walking `properties`, `items`, `anyOf`/`allOf`/`oneOf`, `$defs`/`definitions`) **without mutating
  the caller's schema**, before placing it on `output_config.format`. This is the house
  "normalize the wire quirk, don't gatekeep" stance: the caller's open schema is closed *for* them,
  not refused.
- **A bare `json_object` has no closed native form, so it routes through the synthesized-tool
  path** — the exact ADR 0005 Decision 2 mechanism the legacy `/anthropic` shims use, now shared.
  `_response_format_via_tool` (`:404`, extracted from `_translate_response_format` `:385`) builds a
  tool with an open, **non-strict** `input_schema` (`{ type => object, additionalProperties => true }`)
  and forces it. `chat_request` (`:176`) branches on `_rf_is_native_schema`: native for a schema,
  `_response_format_via_tool` for everything else — so `json_object` gets free-form JSON via the
  non-strict tool exactly where the native validator would 400.
- **On `claude-fable-5-1` / `claude-mythos-5-1` the forced tool degrades to `tool_choice auto`.**
  Those models reject forced tool use; `Engine::Anthropic::model_capability_corrections`
  (`Anthropic.pm:73-74`) clears their `tool_choice_named` / `tool_choice_any` flags (ADR 0019), so
  `_response_format_via_tool` emits `{ type => 'auto' }` instead of `{ type => 'tool', name => … }`.
  Under `auto`, `chat_response` lifts the tool_use only if the model chose to emit it — so free-form
  `json_object` has **no guaranteed** structured path on those two models (recorded, not defended).
- **Streaming: a `json_schema` streams native; a `json_object` croaks.** `chat_stream_request`
  (`:548`) streams a closed `json_schema` as ordinary text deltas, but the synthesized-tool fallback
  has no streaming lift, so a `json_object` on the streaming path croaks loudly (`:575`) rather than
  400 on the wire or stream unstructured text — the same fail-loud posture the shim branch already
  had (karr #52).
- `Engine::Anthropic::_native_structured_output` stays `1` (`Anthropic.pm:47`); the shims stay `0`
  and keep the full Decision 2 rewrite for both `json_schema` and `json_object`.

This **nuances, does not overturn**, the k133 Update: first-party Anthropic still has native
structured output, but only for a schema (normalized closed), while a schemaless `json_object` falls
back to the same rewrite the shims use — so `json_object` is a *capability gap* on this wire after
all, exactly the case Decision 4 anticipated. The unify-and-rewrite core stands. (Verified offline:
`t/77_response_format_per_request.t`, `t/77_response_format_streaming.t`, `t/78_chat_f_controls.t`.)

## Update (k183 — `_close_schema` keeps a map/dictionary `additionalProperties` schema instead of clobbering it)

The k182 Update above describes `_close_schema` as *"recursively sets `additionalProperties:false` on
every object."* That is now **nuanced for one edge**: an `additionalProperties` that is itself a
**schema HashRef** — a dictionary/map value type, e.g. `{ type => 'string' }` (`map<string,string>`)
or a nested object (`map<string,object>`) — is a legitimate JSON Schema construct, **not** an
open-object marker. Clobbering it to `false` would silently drop the map's value constraint. So
`_close_schema` (`AnthropicCompatible.pm:327`) now branches on the *value* of `additionalProperties`
(k183):

- a **HashRef** `additionalProperties` is **kept and recursed into as a subschema** (a
  `map<string,object>` value object is itself closed);
- only an **absent** or **truthy-boolean** (`JSON->true`) `additionalProperties` still means "open
  object" and is set to `false`;
- an already-**explicit `false`** stays `false`.

- **Scope is exactly the map edge.** The rest of the k182 Update is unchanged: `_close_schema` still
  walks `properties` / `items` / `anyOf`/`allOf`/`oneOf` / `$defs`/`definitions`, still closes every
  ordinary object, still does not mutate the caller's schema, and the native-vs-`json_object` routing
  and streaming rules are untouched. It stays the house "normalize the wire quirk, don't gatekeep"
  stance — a caller who genuinely wants free-form values uses `response_format json_object` (the
  non-strict tool path).
- **`_close_schema` does *not* add `required`.** k183's originating question was whether the
  first-party `output_config.format` validator needs a non-empty `required` on a closed schema. It
  does **not** — live-confirmed HTTP 200 without `required` — so `_close_schema` stays
  `additionalProperties`-only and adds no `required` key; only the map edge was fixed. (This is
  separate from `Tool->to_anthropic`'s top-level `strict:true`, which keys on `additionalProperties`
  + a non-empty `required` for the *tool* path — ADR 0001 / the k133 Update — and is unchanged.)

Verified offline: `t/77_response_format_per_request.t` (the map-schema matrix: `map<string,string>`
kept, `map<string,object>` value object recursively closed, an enclosing object without
`additionalProperties` still closed to `false`).

## Update (k218 — native structured output per model: MoonshotAnthropic `kimi-k3`)

Kimi's Messages API (`/anthropic/v1/messages`, platform.kimi.ai `docs/api/messages.md`,
advisor-verified 2026-09-25) documents `output_config.format {type: json_schema, schema}` for
`kimi-k3`, next to `output_config.effort`. `Engine::MoonshotAnthropic` used the shim rewrite on
every model: a synthetic tool plus a forced named `tool_choice`, and no streaming. That is the
worse path on K3, because on Kimi's chat face a forced named tool conflicts with K3's always-on
thinking. `kimi-k3` now takes the first-party native path from the k133/k182 Updates. A
`json_schema` goes out as `output_config.format` with the schema closed, merged with any
`output_config.effort`, and it streams. A bare `json_object` still goes through the synthetic
tool, as it does on first-party Anthropic (the native format is `json_schema` only). The K2.x
line has no documented format on this face and keeps the shim rewrite.

The switch is per model, so the predicate is split in two. `_native_structured_output` still
describes the **endpoint**: first-party native, or a shim. `Langertha::Manifest::Builder` reads it
for the dialect (ADR 0029), so `MoonshotAnthropic` stays `anthropic-compat`. The endpoint is still
a shim, and a dialect that flipped with the configured model would misdescribe the other models
on the same endpoint. The request builders (`chat_request`, `chat_stream_request`) now ask
`_native_structured_output_for_model`, which defaults to the endpoint predicate.
`MoonshotAnthropic` overrides it to true for `qr/\Akimi-k3(?!\d)/`. It is a method rather than an
ADR 0019 capability row because it picks a wire path, not a flag that a caller would query.
Documentation only, not live-verified. The closed-schema normalization (k182) was written for the
first-party validator and is assumed acceptable to Kimi. Pinned by
`t/77_response_format_moonshot_native.t`.

## Update (k213 — Perplexity has client function tools now; direction 1 still fires)

The Context's "Perplexity does no tool calling at all" is stale since the Agent API move (k139):
the Agent API takes client-executed function tools, and Perplexity now composes `Role::Tools`
(`tools_native` on). Its request schema has no `tool_choice` field, so every `tool_choice_*` flag
stays cleared. The direction-1 condition (`!supports('tool_choice_named') &&
supports('response_format_json_schema')`) therefore still holds, a forced named tool is still
rewritten to `response_format=json_schema` plus a synthetic `ToolCall`, and Perplexity remains
the exemplar. What changed is only the unforced case: `tools` without a forced choice now go out
as native function tools. Pinned in `t/68_perplexity_function_tools.t` and
`t/68_perplexity_agent.t`.

## Update (k234 — the hermes wire takes direction 1; the schema also rides the system prompt)

The hermes engines (`NousResearch`, `AKI` native) used to claim `tools_native` and every
`tool_choice_*` through `Role::Tools`, so direction 1 never fired on them (ADR 0001, k231 Update).
`Role::HermesTools` now clears the native flags (ADR 0002, k234 Update). `NousResearch` keeps the
`response_format_json_{object,schema}` flags from `OpenAIBase`, so a forced named tool there is
rewritten to `response_format=json_schema` plus a synthetic `ToolCall`, as on Perplexity. The
rewrite runs before `_hermes_prompt_tools`, so the tools and the choice are already gone and no
tool prompt is sent.

On a hermes engine that takes `response_format` (NousResearch), every `json_schema` response
format also goes into a leading system message, built from `hermes_schema_prompt` (the Hermes
structured-output form, `<schema>…</schema>`). That covers the rewrite, a `response_format` the
caller passes to `chat_f` or `chat_stream_realtime_f`, and the engine's own attribute. Whether the
Nous backend enforces `response_format` is not documented, and a Hermes model follows a schema in
its system prompt, so neither the synthetic `ToolCall` nor a caller's structured output depends on
the backend honoring the field. The schema prompt goes in front of the tool prompt.
`AKI` native has no `response_format` field, so direction 1 cannot fire there: a forced choice is
still dropped with a carp (k231), and the POD points to `AKIOpenAI`. Streaming has no rewrite, but
it does get the schema prompt. Documentation only, not live-verified. Pinned in `t/69_chat_f_wire_tools.t`.

## Update (k250 — the rewrite no longer replaces a caller's response_format silently)

Direction 1 sets a per-request `response_format` (the forced tool's `json_schema`), which replaces
whatever `response_format` the request would otherwise carry. That used to happen silently, so a
caller who asked for both got the tool's schema back instead of the shape they asked for. Where
the other `response_format` comes from decides the outcome; the source is read with
`_chat_effective_response_format` (ADR 0024, k249 Update), the precedence the request builders use:

- **Passed to the same `chat_f` call** (any type but `text`, `json_object` included): the caller
  asked for two different outputs in one request. `chat_f` croaks before sending and the message
  says to pick one. This also covers a per-request value that repeats the engine's.
- **Only on the engine attribute**: the request is the more specific intent, so the forced tool
  wins. The rewrite goes ahead and carps that the engine's `response_format` is replaced for this
  request.
- **`text`**, from either source, asks for no structure, so it is not a conflict: the rewrite
  stays silent, as before.

The check runs only when the rewrite actually fires (named tool found in `tools`), inside
`_chat_rewrite_replaces_response_format`. On NousResearch the hermes schema prompt (k234 Update)
carries the rewritten tool schema, because it reads the controls after the rewrite. Ollama's
legacy `json_format` attribute is not a `response_format` and is still overridden silently.
Streaming has no rewrite, so it is unaffected. Pinned on Perplexity, Ollama native and
NousResearch in `t/77_forced_tool_response_format_conflict.t`.

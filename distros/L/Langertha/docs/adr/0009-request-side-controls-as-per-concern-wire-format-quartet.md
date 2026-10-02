# ADR 0009 — Request-side control params are modeled as a per-concern wire-format quartet

- Status: accepted
- Date: 2026-06-26
- Tags: engines, roles, value-objects, wire-format, reasoning, prompt-cache, capabilities

## Context

Some request-side control knobs vary by provider on *both* axes ADR 0001 already
fights on the tools side: the accepted **vocabulary** differs, and the **placement** of
the field in the request body differs. Reasoning effort is the worst case — the same
normalized intent ("think harder") is a flat `reasoning_effort` string on OpenAI
`/chat/completions`, a nested `reasoning:{effort}` on the Responses API,
`output_config.effort` plus `thinking:{type:adaptive}` on Anthropic Messages, and a
model-gated `generationConfig.thinkingConfig.thinkingLevel`
(`minimal`/`low`/`medium`/`high`, with the accepted subset varying by Gemini model
family) on Gemini — and each wire accepts only a subset of the normalized value set.
Prompt caching
is similarly split: Anthropic exposes an explicit `cache_control` enable breakpoint with a
TTL, while OpenAI caches automatically and the only request-side lever is the
`prompt_cache_key` routing hint.

The pull to model each of these ad-hoc, per engine, is strong — and the codebase already
had one such ad-hoc knob that proves the cost: `AnthropicBase` carried an `effort`
attribute that emitted a **top-level `effort` key**, which the Messages API silently
ignores (a dead request field, exactly the class of bug ADR 0004 names). The placement was
wrong, not the idea.

The deeper structural question this decision answers: ADR 0001 routes the tools seam
through value objects keyed by a single `tool_wire_format` tag — can a control knob just
reuse that tag? No. Engines that agree on `tool_wire_format=openai` (DeepSeek, MiniMax,
Groq) **disagree** on the reasoning field: MiniMax's OpenAI endpoint rejects it entirely,
DeepSeek's V4 line takes a flat `reasoning_effort` while its legacy V3.2 line took a
`thinking:{type:enabled}` toggle, and Groq accepts the flat form. One global wire format
cannot express that. Wire dialect is **per concern**.

## Decision

Each request-side control param that varies by provider is modeled as a consistent
**quartet**, not as ad-hoc per-engine code. The two knobs that landed together —
`Langertha::Role::ReasoningEffort` / `Langertha::Reasoning` and
`Langertha::Role::PromptCache` / `Langertha::PromptCache` — are the same shape and are
recorded as one decision.

1. **A predicate-gated role holds the normalized attribute(s).** `Role::ReasoningEffort`
   carries `reasoning_effort` (normalized vocabulary: the OpenAI superset
   `none|minimal|low|medium|high|xhigh|max`); `Role::PromptCache` carries `prompt_cache`
   / `prompt_cache_ttl` / `prompt_cache_key`. The field is emitted only when set — the
   same "only when present" discipline as `Role::Temperature`, so an unset knob means the
   model's own default applies and no field reaches the wire.

2. **A per-format value object owns the wire shape.** `Langertha::Reasoning` and
   `Langertha::PromptCache` each carry `to_<fmt>` serializers plus a `to($fmt)` dispatch
   (`croak` on an unknown tag). Each serializer does two jobs: it **clamps** the
   normalized vocabulary to what that wire accepts (returning an empty list when the value
   has no equivalent — e.g. Anthropic drops `none`/`minimal`, OpenAI drops `max`, Gemini
   maps onto `minimal`/`low`/`medium`/`high` clamped down to the configured model
   family's accepted subset), and it **places** the field correctly
   (Anthropic `output_config.effort` + `thinking:{type:adaptive}`; OpenAI flat
   `reasoning_effort`; Responses nested `reasoning:{effort}`; Gemini
   `generationConfig.thinkingConfig.thinkingLevel`; Anthropic `cache_control`; OpenAI
   `prompt_cache_key`). This is exactly the instinct of ADR 0001 — the
   Tool/ToolCall/ToolResult/ToolChoice value objects own tool wire translation so engines
   stay thin — applied to a new family of value objects.

3. **A dedicated `*_wire_format` tag per concern, deliberately separate from
   `tool_wire_format`.** `reasoning_wire_format` and `cache_wire_format` each default off
   the engine base-class hierarchy (`_build_*` returns `openai`; `AnthropicBase` overrides
   both to `anthropic`; `Gemini` sets `reasoning_wire_format` to `gemini`;
   `OpenAIResponses` to `responses`) — the same base-encodes-the-dialect arrangement as
   ADR 0006, but **one tag per concern**. This is the load-bearing new point: a single
   global wire format is insufficient because engines sharing one dialect for one concern
   diverge on another. Wire dialect is per concern, so the tag is per concern.

4. **Capability flags ride the existing registry (ADR 0002).** `%ROLE_TO_CAPS` registers
   `Role::ReasoningEffort → reasoning_effort` and `Role::PromptCache → prompt_cache
   prompt_cache_key`, and base classes / engines clear flags the wire cannot honor via
   `around engine_capabilities`: `OpenAIBase` clears `prompt_cache` (OpenAI caches
   automatically — only the routing key applies), `AnthropicBase` clears
   `prompt_cache_key` (it has the enable breakpoint but no routing key),
   `MiniMax`/`Perplexity` clear `reasoning_effort`, `Perplexity` also clears
   `prompt_cache_key`. As ADR 0002 establishes, the flag means **the wire accepts the
   field**, not that any given model will honor it (every reasoning field 400s on a
   non-reasoning model). Prompt caching is request-side-asymmetric, which is *why* it gets
   two flags from one role rather than one.

5. **Engines override the kwargs dispatch for model-gated divergence below the tag's
   resolution.** The role's `reasoning_kwargs` / `prompt_cache_kwargs` is the seam the
   request builder calls (`Role::OpenAICompatible` emits both, `can`-guarded, in its chat
   and stream requests; `AnthropicBase` and `Gemini` call them in their own builders).
   When divergence lives *within* a shared wire format — below the format tag's resolution
   — the engine overrides the method: `DeepSeek::reasoning_kwargs` sniffs the model (V4
   flat `reasoning_effort` vs legacy V3.2 `thinking:{type:enabled}`), and
   `MiniMax`/`Perplexity` stub it to an empty list.

As part of this, the dead-key bug is fixed: `AnthropicBase`'s top-level `effort` becomes
`output_config.effort` + `thinking:{type:adaptive}` via `Langertha::Reasoning`, with
`effort` kept as a back-compat alias of `reasoning_effort` (seeded in `BUILDARGS`).
Live-verified HTTP 200 on `claude-opus-4-8`. ADR 0004's "extras extend the body" was the
right mechanism; only the *placement* was wrong, and the value object is now where
placement is decided once.

## Rationale

The tools seam (ADR 0001) proved that wire reality belongs in canonical value objects
dispatched by a per-engine tag, leaving engines as configuration. Request-side control
knobs are the same kind of problem — normalized intent in, provider-shaped field out — so
they get the same shape rather than a second, ad-hoc style. The one genuinely new insight
is that the tag must be **per concern**: `tool_wire_format` cannot be reused because the
agreement it encodes (which tool dialect) does not imply agreement on reasoning or
caching. Splitting the tag per concern is what keeps DeepSeek, MiniMax, and Groq — three
`tool_wire_format=openai` engines — able to disagree about reasoning while still sharing
everything else.

Keeping the value object responsible for both clamping and placement means a wire-shape
fix happens once and every engine of that format inherits it — and it makes the dead-key
class of bug structurally hard to reintroduce, because no engine writes the field
position by hand anymore.

## Consequences

- **A new request-side control concern** = a new quartet: a predicate-gated role, a value
  object with `to_<fmt>` + `to()`, a `*_wire_format` tag defaulting off the base
  hierarchy, a `%ROLE_TO_CAPS` entry (plus `around` corrections where the wire
  disagrees), and a `can`-guarded emission in the request builders.
- **A provider variation within an existing concern** = either a new tag value with a new
  `to_<fmt>` branch (a whole new dialect) or, when the split is below the tag — e.g.
  model-gated — an engine-level override of the `*_kwargs` method. Pick by where the
  divergence actually lives.
- **A capability flag means the wire accepts the field, not that the model honors it.**
  Prompt caching therefore carries two flags (`prompt_cache` enable breakpoint vs
  `prompt_cache_key` routing hint), each cleared on the family whose wire lacks it.
- The normalized vocabularies (`reasoning_effort`'s seven values, the cache TTL windows)
  are the stable public contract; what each wire accepts is the value object's private
  knowledge, expressed as clamping.

## Future work

- **`CONTEXT.md` covers only the tool wire-translation vocabulary.** It does not yet name
  `reasoning_wire_format` / `cache_wire_format`, `Langertha::Reasoning` /
  `Langertha::PromptCache`, or the "per-concern wire format" relationship. Extending the
  domain language so these sibling seams are first-class terms (not just analogues of the
  tools seam) would keep the vocabulary truthful. Candidate karr follow-up.
- **DeepSeek's V3.2 `thinking:{type:enabled}` mapping is flagged for live re-verify** in
  the code comment — the V4 path is live-verified, the legacy toggle is not.

## Cross-links

- ADR 0001 — tool wire-translation via value objects keyed by `tool_wire_format`; this
  ADR applies the same value-object-owns-the-wire pattern to control params and explains
  why the *tag* must be per concern rather than shared.
- ADR 0002 — capabilities derive from the composed role inventory; the new flags are
  registered in `%ROLE_TO_CAPS` and corrected via `around engine_capabilities`.
- ADR 0004 — provider wire extras extend the request body; this ADR fixes the Anthropic
  `effort` *placement* (dead top-level key → `output_config.effort` +
  `thinking:{type:adaptive}`) by moving placement into the value object.
- ADR 0006 — engine inheritance encodes the wire dialect; this ADR extends that from one
  dialect tag to one tag *per concern*.

## Update (k133 — `output_config` is now shared by two concerns)

This ADR's quartet places each concern's field into a **disjoint** body key: reasoning effort
lands under `output_config.effort` (+ `thinking`), prompt cache under `cache_control` /
`prompt_cache_key`. k133 broke the disjointness. Native Anthropic structured output (the ADR
0005 Update) places its schema under `output_config.format` — the **same** `output_config`
object `Langertha::Reasoning::to_anthropic` writes `effort` into. Structured output is not
itself a quartet member (its `response_format` rides the dialect role's generation-parameter
block per `CONTEXT.md`, not a `*_wire_format` value object), but it now writes the same body
region as one.

Two concerns sharing one body key cannot be composed by assignment — a second `output_config`
would silently drop the first. The resolution is a merge seam:
`Role::AnthropicCompatible::_merge_output_config_format` folds `format` into whatever
`output_config` the generation kwargs already hold. This is the quartet's first shared body
key; any later concern that also writes `output_config` must merge through the same seam rather
than assign.

## Update (k200 — `prompt_cache_key` is per-engine within the OpenAI family, and the wire follows the flag)

Point 4 cleared `prompt_cache` on `OpenAIBase` and kept `prompt_cache_key` for the whole
family. That over-claimed for the self-hosted OpenAI-compatible servers: none of them reads
OpenAI's routing hint on `/v1/chat/completions`. vLLM's `ChatCompletionRequest` accepts and
ignores unknown keys (it declares `prompt_cache_key` only on its `/v1/responses` protocol),
SGLang's drops them, Ollama's `/v1` Go struct has no such field, llama.cpp neither documents
nor reads it, and LM Studio's documented parameter list omits it. Their prefix-cache levers
are the `Runtime::Knobs` of ADR 0012. So `vLLM` (and `VLLMHook` by inheritance), `SGLang`,
`LlamaCpp`, `OllamaOpenAI` and `LMStudioOpenAI` now delete `prompt_cache_key` in their own
`around engine_capabilities` (ADR 0002 layer 2). There is no shared self-hosted base to hang
one correction on, so each engine carries it next to its other wire corrections. Cloud
subclasses keep the flag: OpenAI and OpenRouter document the field; the rest are unverified
and stay as the base advertises them until their docs or a live test decide.

The second half is new to the quartet: **the wire agrees with the capability for the routing
key**. `Role::PromptCache::prompt_cache_kwargs_for` drops `prompt_cache_key` (engine attribute
or per-request control) when `supports('prompt_cache_key')` is false, so clearing that flag
also stops its emission; no per-engine `prompt_cache_kwargs_for` stub is needed (unlike the
MiniMax/Moonshot `reasoning_kwargs_for` stubs). The drop is silent, like those stubs: the
servers ignored the key anyway. `prompt_cache` is deliberately **not** gated. Its flag is
cleared family-wide on `OpenAIBase`, yet `cache_wire_format` is a public attribute, and an
OpenAI-family engine configured with `cache_wire_format => 'anthropic'` (an OpenAI-compatible
proxy in front of Claude) must keep sending `cache_control`; gating the family flag would
silently drop it. The request body changes only where `prompt_cache_key` was cleared. Because
the provider manifest (ADR 0029) reads the same registry, those engines' model entries stop
publishing `prompt_cache_key` too. ADR 0015's direction-pair table still holds per family;
this refines "all subclasses of `OpenAIBase`" per engine.

## Update (k204 — the reasoning concern follows the registry too; the engine stubs retire)

After k200 the quartet stated "this engine takes no such control" two ways: `prompt_cache_key`
through the registry gate in its role, reasoning through empty `reasoning_kwargs_for` stubs on
`MiniMax` and `Moonshot`, each sitting next to an `around engine_capabilities` that already
cleared `reasoning_effort`. The fact now has one home, the registry.
`Role::ReasoningEffort::reasoning_kwargs_for` returns an empty list when the engine advertises
**neither `reasoning_effort` nor `thinking_budget`**, and the two stubs are gone. Point 5's
"engines stub it to an empty list" is retired. The Perplexity stub it also names had already gone:
Perplexity now keeps `reasoning_effort` and sends `reasoning.effort` over the `responses` wire.

**Why both flags, not `reasoning_effort` alone.** The concern has two request flags. Only three
places clear `reasoning_effort`, all at layer 2: `MiniMax` and `Moonshot` for every model, and
`Gemini` for `gemini-2.5-*`. No `model_capability_corrections` entry (layer 3) touches it today.
Gemini 2.5 clears `reasoning_effort` because it takes an integer `thinkingBudget` instead, and it
advertises `thinking_budget`. A gate on `reasoning_effort` alone would have dropped that
accepted `thinkingBudget`, which would be a regression. It would also have turned the deliberate
`effort`-on-2.5 croak of `Langertha::Reasoning::BUILD` (ADR 0023) into a silent drop. Gated on
"neither flag", Gemini 2.5 is untouched: the concern is live there, and the value object stays
responsible for rejecting the wrong sub-control loudly. MiniMax and Moonshot advertise neither
flag, so the gate drops everything the stubs dropped, `thinking_budget` included, which would
otherwise croak in `BUILD`.

**The k200 hazard does not apply.** k200 left `prompt_cache` ungated because its flag is cleared
family-wide on `OpenAIBase` while `cache_wire_format` is a public override (a proxy in front of
Claude). `reasoning_effort` is never cleared on a dialect base, only on the two leaf engines and
one Gemini model family. Their stubs ignored a `reasoning_wire_format` override too, so the gate
drops nothing new.

**`DeepSeek::reasoning_kwargs_for` stays.** It does more than gate: it picks the placement per
model (V4 flat `reasoning_effort` vs V3.2 `thinking:{type:enabled}`) and clamps the V4 value set.
DeepSeek never clears the flag, so bypassing the role's gate costs nothing today. A future
DeepSeek flag clear must add the gate to that override.

**The drop stays silent.** The stubs were silent, and so is the k200 gate. ADR 0025's
temperature carp covers a value the model would reject with a 400 while the caller cannot see
why. Here the engine publicly declares, through `supports('reasoning_effort')`, that it takes no
reasoning control, and nothing would error. Adding a carp would be a new warning on every request
for users who set the attribute once. That is a behavior change a pure consolidation should not
carry, and it is open for its own ticket if wanted.

The change is behavior-preserving. `t/47_reasoning_capability_gate.t` pins the canonical chat and
stream request bodies (or the croak) of every engine that composes the role, across
representative models and every reasoning setting (1118 rows, captured from the stub-based code
before the change, byte-identical after). It also proves that the wire follows the flag in both
directions: a MiniMax subclass that re-asserts `reasoning_effort` emits it, and an OpenAI subclass
that clears it stops emitting without a stub. No `Changes` entry, since no body changed.

## Update (k207 — Moonshot's reasoning clear moves to layer 3)

The k204 update's inventory is out of date: `Moonshot` no longer clears `reasoning_effort` for
every model. The clear is now a `model_capability_corrections` row on the K2.x line (ADR 0019
k207 update), the first layer-3 entry for this flag. The gate needs no change, because it reads
`supports()`, which already applies layer 3. Layer-2 clears remain on `MiniMax` and on `Gemini`
for `gemini-2.5-*`.

## Update (k209 — MiniMaxAnthropic strips `output_config.effort` at the engine)

MiniMax's `/anthropic` `CreateMessageReq` has a `thinking` object (default disabled on M3) but no
`output_config`, yet `MiniMaxAnthropic` inherited the `anthropic` serializer and sent
`output_config.effort`. It now wraps `reasoning_kwargs_for` with an `around` that removes
`effort` from `output_config` (and the key when nothing else is left) and keeps
`thinking:{type:adaptive}`, which is how an effort turns thinking on there. This is the
"wire divergence within a shared format" case the method's POD already allows (DeepSeek is the
other). It is deliberately not a `Reasoning::Profile` row, as the advisor first suggested: the
missing field belongs to MiniMax's endpoint for every model, not to a model id (a `MiniMax-*`
row would also reach other engines that serve that id), and the Profile has no way to say "drop
the effort, keep the thinking block". The capability flag stays on, because the endpoint takes a
reasoning control, and `MiniMax`'s layer-2 clear on the OpenAI face is unchanged. The binary
`thinking` toggle of MiniMax-M3 on `chat/completions` (`none` to `thinking:{type:disabled}`) is
still unreachable; it needs a reasoning wire mapping and stays open on karr k209. Source:
MiniMax `openapi-chat-anthropic.json`, advisor-verified 2026-09-25 — documentation only, not
live-verified.

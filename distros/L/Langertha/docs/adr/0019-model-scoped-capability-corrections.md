# ADR 0019 — Model-scoped capability corrections (amendment to ADR 0002)

- Status: accepted
- Date: 2026-09-10
- Tags: capabilities, tools, chat_f, roles, model-scoped

## Context

ADR 0002 built the capability picture in two layers: **layer 1** derives the flag set from the
composed role inventory (`%ROLE_TO_CAPS` in `Role::Capabilities`), and **layer 2** lets an
engine correct wire reality via `around engine_capabilities` — the one sanctioned escape hatch
for "the role inventory over-promises, the wire never accepts this field."

Both layers resolve **per engine**. That is the flaw on the tool / structured-output axis. A
red-team pass (karr k138) dumped `engine_capabilities` across the OpenAI-dialect fleet and found
literally one flag row — `tools_native tool_choice_auto tool_choice_any tool_choice_none
tool_choice_named response_format_json_object response_format_json_schema` — repeated across
~17 engines, ~11 of them wrong. The layer-2 escape hatch was in use only a handful of times and
none of those touched a tool-choice or structured-output flag, so the fleet advertised
capabilities it could not deliver.

That dishonesty is not cosmetic. `chat_f`'s auto-rewrite matrix (ADR 0005) decides whether to
forward a forced `tool_choice`, reroute it through `response_format`, or drop it — keyed on
`supports()`. When the flags are a constant, the decision is a constant: several engines
silently dropped a `tool_choice` the caller believed was forced, and the failure was a wrong
answer, not an error.

The deeper reason the flags were wrong is that **the tool / structured-output wire reality is
frequently per-model, not per-engine.** Within one endpoint, `kimi-k3` forbids a forced named
tool (its thinking mode disallows it) while its `kimi-k2.*` siblings accept one; a reasoning
model's clamps differ from its chat sibling on the same base URL. ADR 0002's engine-scoped
`around` cannot express "this field, but only for that model" without the engine hand-rolling a
`chat_model` branch inside its own `around` — which several engines had already begun to do
ad hoc (Gemini's `around` switches `thinking_budget` / `reasoning_effort` / `cached_content` on
a model regex).

## Decision

**Capability corrections resolve on two scopes, and the scope decides where the correction
lives.**

1. **Engine-wide reality → layer 2, `around engine_capabilities` (unchanged from ADR 0002).**
   When the endpoint never accepts a field regardless of model — MiniMax's `/v1` schema omits
   `tool_choice`/`response_format` entirely, OllamaOpenAI silently ignores `tool_choice` — the
   correction is model-independent and stays in the engine's `around`. This is the **outer
   endpoint gate.**

2. **Per-model reality → layer 3, a declarative `model_capability_corrections` table.** When the
   endpoint *carries* the field but a specific model or family rejects it, the engine declares
   an **ordered list of `( $matcher => \%overrides )` pairs** from `model_capability_corrections`.
   `Role::Capabilities::engine_capabilities` applies them, after layer 1, against the currently
   selected `chat_model`. The default returns an empty list, so engines that need no per-model
   refinement pay nothing.

3. **Layer 1 (role derivation, `%ROLE_TO_CAPS`) is untouched.** It remains the single source of
   the base flag set.

### Chosen form

- **Matcher** is either an exact model-id string (matched with `eq`) or a `qr//` regex (matched
  against `chat_model`). Model ids come in families (`gpt-5.6-*`, `kimi-k2.7-*`), so both a
  point match and a family match are first-class.
- **Overrides** is `{ $cap => 1 | 0 }` — `1` asserts a flag, `0` clears it.
- **Later matching entries win** on a shared flag (ordered list, last write wins).
- **Booleans only.** A pairwise / mutual-exclusion constraint between two capabilities (Cerebras
  and Groq reject `tools` + `response_format` in one body) is explicitly **not** expressible in
  this table — see *Future work* (karr k142).

The keystone user is `Engine::Moonshot`:

```perl
sub model_capability_corrections {
  return (
    'kimi-k3'       => { tool_choice_named => 0 },  # thinking forbids a forced tool
    qr/\Akimi-k2\./ => { tool_choice_any   => 0 },  # K2.x has no `required`
  );
}
```

`chat_model = 'kimi-k3'` loses `tool_choice_named`; a `kimi-k2.7-*` model loses `tool_choice_any`
instead; a future Moonshot model keeps the role-derived base until the table names it. This is
the **named form** of what Gemini's `around` already did ad hoc — the pattern is not new, it is
now a declared seam instead of an open-coded branch.

## Rationale

**Why a third layer rather than folding per-model logic into the existing `around`.** An engine
*could* read `chat_model` inside its `around` and branch — Gemini does. But that buries the
per-model matrix in imperative code, one engine at a time, invisible to any reader who greps for
the capability. A declarative, ordered table keyed on `chat_model` is greppable, testable
(k138's `t/78_model_scoped_capabilities.t` proves per-model *and* per-engine discrimination,
sabotage-verifiable), and gives the two distinct wire realities two distinct homes: "the
endpoint refuses this" vs "this model refuses this."

**Ordering semantics — recorded so nobody has to re-derive them.** The engine-wide `around`
*wraps* `engine_capabilities`, so it runs **outside** — and therefore **after** — the layer-3
table baked into the base method. The `around` is thus the last word over any per-model
correction. That is defensible on its own terms: **the endpoint gate is absolute** — if the wire
never accepts a field, no model can rescue it, so a layer-2 clear rightly overrides a layer-3
assert. In all current data the two layers touch **disjoint flags**, so the ordering is not
load-bearing today; the two in-flight consumers (k133 Anthropic fable/mythos, k140 OpenAI /
Gemini clamps) both use the dominant **clear-for-exceptions** shape (the base grants a flag,
a per-model entry clears it for the exceptional model), which is order-independent by
construction. The rule is written down here precisely because it is currently invisible.

**Precedent and related sites.** The mechanism names a pattern already present unnamed in
several places, none migrated in k138 (out of scope), all consolidation candidates:

- `Engine::Gemini`'s `around` — model regex → sets/clears `thinking_budget` / `reasoning_effort`
  / `cached_content`. The closest match to the new table; the strongest candidate to migrate.
- `Engine::OpenAI::_max_tokens_key`, `Reasoning::to_gemini_level`, `Reasoning::_is_fable_class`,
  `Engine::DeepSeek::reasoning_kwargs_for` — other per-model gating, on the reasoning/request-side
  axis rather than the capability flags.

## Consequences

- **The mechanism is ready** for the two waiting tickets: k133 (Anthropic native structured
  output — `fable`/`mythos` reject the ADR 0005 synthetic-tool rewrite) and k140 (OpenAI /
  Gemini reasoning and structured-output clamps). Both are per-model, both fit the table.
- **Only `Engine::Moonshot` uses layer 3** so far. The rest of the k138 pass is a broad
  **layer-2** honesty sweep informed by the same wire-reality matrix: MiniMax, OllamaOpenAI,
  LlamaCpp, SGLang, Hetzner, DeepSeek, and Scaleway each clear engine-wide flags their endpoint
  never delivers. The two mechanisms are complementary, not competing: pick the scope that
  matches the reality.
- **The flag contract is unchanged:** a capability flag still means *the wire accepts the
  field*, not that a model will honor it — now resolved for the selected `chat_model` rather than
  once per engine. `supports()` and the `chat_f` matrix are downstream and need no change.
- **The correction matrix is verified-but-not-infallible — cross-check the canonical→wire
  serialization before trusting a "wrong flag" reading.** Building k138 surfaced one such error
  in the advisor matrix (House Rule 5 — surface the conflict, don't average it): **Scaleway
  `tool_choice_any` is NOT wrong.** The matrix flagged it by reading OpenAI's literal `"any"`,
  but Langertha's canonical `any` serializes to the wire token `tool_choice: "required"`
  (`Langertha::ToolChoice::to_openai`), and Scaleway's enum is exactly `none | auto | required` —
  so `any` is accepted. Only `parallel_tool_use` (inert on Scaleway) and the deprecated
  `response_format_json_object` were cleared there. The lesson is load-bearing for every future
  correction: a capability flag names a *canonical* capability, and whether the wire accepts it
  is decided by what the value object *emits*, not by matching the flag's spelling against the
  provider's enum.

## Future work

- **karr k142** — pairwise / mutual-exclusion capability constraints. Cerebras and Groq reject
  `tools` + `response_format` in one request; the boolean table (even model-scoped) cannot
  express "these two capabilities are mutually exclusive per call." This also dents the ADR 0005
  premise that structured output and forced tools are freely interchangeable. Out of scope here;
  do not stretch the boolean table to fake it. **Update (2026-09-14):** the interim guard shipped
  as **ADR 0021** — a per-engine `_check_capability_exclusions` croak at the `chat_f`/streaming
  layer, above this table, that turns the known provider 400 into a clear local error. The
  model-scoped generalization this bullet describes (a new per-model seam beside the boolean
  table) remains parked for the maintainer; karr k142 stays open for it.
- **Gemini consolidation** — migrate `Engine::Gemini`'s ad-hoc model-regex `around` into
  `model_capability_corrections`. It is the pattern this ADR names; folding it in would remove
  the last open-coded per-model capability branch. Deliberately not done in k138 (Gemini is not
  on the OpenAI-dialect axis the ticket scoped). Not yet ticketed — a consolidation candidate,
  not a defect.

`CONTEXT.md` carries the vocabulary (`capability axis`, `model_capability_corrections`). See
ADR 0002 (the base decision this amends), ADR 0005 (the auto-rewrite matrix `supports()` feeds),
and ADR 0015 (per-family `around` corrections, the layer-2 sibling of this per-model table).

## Update (k207 — the first layer-3 clear of `reasoning_effort`: Moonshot's K2.x line)

`Engine::Moonshot` cleared `reasoning_effort` at layer 2 for every model, so an explicit effort on
`kimi-k3` was dropped silently although K3 documents a top-level `reasoning_effort`
(`low|high|max`, default `max`) on `chat/completions`. The K2.x line takes only the Kimi
`thinking` object. That is per-model wire reality, so it moves to this table: the layer-2
`around engine_capabilities` is gone, and the K2 row, widened to `qr/\Akimi-k2(?!\d)/` so dash-form ids such as `kimi-k2-thinking` are
covered too, now reads `{ tool_choice_any => 0, reasoning_effort => 0 }`. Only the
`reasoning_effort` half is documented for the dash-form ids; the `tool_choice_any` clear
(documented for the dotted K2.x line) is extrapolated to that discontinued 2026-05-25 preview
series — low exposure, accepted rather than split into a second row. The accepted K3 vocabulary lives in its
`Reasoning::Profile` row (ADR 0023), not here: the flag only says the wire takes the field.

The ADR 0009 k204 gate (`supports('reasoning_effort') || supports('thinking_budget')`) sees the
layer-3 result through `supports()`, so K2.x still sends nothing, `thinking_budget` included.
`kimi-k3` now takes the reasoning concern like every other effort engine, and with it the
`Langertha::Reasoning::BUILD` croak on a `thinking_budget` for a non-Gemini-2.5 model, where the
layer-2 clear used to drop that budget silently. Moonshot ids that match neither row (a new
`kimi-*` id, the sunset `moonshot-v1-*`) now advertise `reasoning_effort` and get the
passthrough profile. Source: platform.kimi.ai models overview, `use-reasoning-effort` guide and
`api/chat` schema, advisor-verified 2026-09-25 — documentation only, not live-verified.

## Update (k209 — a catch-all first row lets one model re-enable an endpoint-wide clear)

`Engine::MiniMax` cleared `reasoning_effort` at layer 2 for every model. MiniMax-M3 has a
controllable thinking toggle on `chat/completions` (ADR 0023 k209 Update), but M2.x and unknown
ids have none. Layer 3 runs *inside* the layer-2 `around`, so a layer-3 row cannot re-enable a
flag that layer 2 deletes. The clear therefore moves into this table as a catch-all first row,
and the model row that wins over it comes after:

    qr/\A/                => { reasoning_effort => 0 },
    qr/\AMiniMax-M3(?!\d)/ => { reasoning_effort => 1 },

This is the table's existing "later matches win" rule, used for a default-deny. Use it only when
one model must opt back in to something the rest of the endpoint lacks. The catch-all must also
hold without a model: `_apply_model_capability_corrections` used to skip the table when
`chat_model` was undef or empty, so `model => ''` fell back to the role default and MiniMax sent
`reasoning_effort` again (review M8). An empty or undef `chat_model` is now matched as `''`;
only a row that matches the empty string (the catch-all) can fire on it. A flag that no model on
the endpoint takes stays in layer 2. The other MiniMax clears (`tool_choice_*`,
`response_format_*`, `parallel_tool_use`) are endpoint-wide and stay in the `around`.

## Update (k219 — an exact-id row re-enables one model inside a family clear)

`Engine::Moonshot` re-enables `reasoning_effort` for `kimi-k2.6` alone, with an exact-id row
after the K2 family row:

    qr/\Akimi-k2(?!\d)/ => { tool_choice_any => 0, reasoning_effort => 0, temperature => 0 },
    'kimi-k2.6'         => { reasoning_effort => 1 },

This is the k209 opt-back pattern with a family row where k209 used a catch-all. The later row
wins. Only the one flag comes back; `tool_choice_any` and `temperature` stay cleared.
`kimi-k2.6` takes a top-level `thinking` object with `type` `enabled|disabled` on
`chat/completions` (`KimiK26ChatRequest` schema, kimi-k2-6-quickstart). The engine now opts in
to the thinking toggle, so the flag reaches the wire as that object (ADR 0023 k219 Update).
`kimi-k2.7-code` and `kimi-k2.7-code-highspeed` stay cleared. The toggle offers them nothing to
send: `disabled` is an error, and the guides say not to pass `thinking` at all. They also do not
agree on whether `{type:'enabled'}` without `keep:'all'` is accepted. A flag that can only ever
serialize to nothing, or to a form the docs disagree on, stays off. This is unlike
`MoonshotAnthropic`, where k2.7-code keeps the flag because that face documents `enabled` as
accepted. Source: platform.kimi.ai `docs/api/models-overview.md`, `docs/api/chat.md`, the K2.6
and K2.7-code quickstarts, advisor-verified 2026-09-25. This is documentation only and not
live-verified.

## Update (k225 — a per-model *default* gets the same table shape, outside the capability layer)

Kimi counts `reasoning_content` against `max_tokens` and recommends `max_tokens >= 16000` while
thinking is on (platform.kimi.ai, advisor 2026-09-25 on k219, docs only). Both Moonshot faces
default `response_size` to 4096, so thinking replies could truncate before the answer. The fix
is per model, not a raised engine default: `kimi-k3` and `kimi-k2.7-code(-highspeed)` always
think and `kimi-k2.6` thinks by default; any other id keeps 4096.

No per-model default mechanism existed, so `Role::ResponseSize` gains one in this ADR's shape:
`sub model_response_size_defaults { ( $matcher => $tokens, ... ) }`, an ordered list matched
against `chat_model` (exact id or `qr//`, later matches win). `get_response_size` resolves
explicit `response_size` → the matching per-model default → `default_response_size`. A
per-request `max_tokens` control still wins over all three in the wire roles. `Engine::Moonshot`
and `Engine::MoonshotAnthropic` carry the same two rows (16000), because the same models think
on both faces (k215, k219). The default is not a capability, so it does not go into
`model_capability_corrections`. It reuses that table's matching rules but stays a separate hook
on the role that owns the value. An explicit value is never raised: a caller who sets a
`response_size` has chosen the ceiling. Cost is unchanged for replies that already fit, because
`max_tokens` is a ceiling and Kimi bills the tokens produced. `kimi-k2.6` with
`reasoning_effort => 'none'` also gets 16000. The row is per model, not per effort, and a higher
ceiling does not hurt a non-thinking reply. The golden reasoning table (t/47) changed only in
`max_tokens` on the Moonshot and MoonshotAnthropic Kimi rows (4096 → 16000); the foreign-engine
Kimi rows (vLLM, AKIAnthropic) are unchanged; the one full-body kimi-k3 pin in
`t/48_reasoning_profile_moonshot.t` moved with it. This is documentation only and not live-verified.

## Update (k266 — `image_input` is model-scoped: "the model sees the image", not wire-only)

`image_input` (from `Role::ImageInput`, a capability role per ADR 0016) is the one flag whose
contract is stronger than *the wire accepts the field*. Composing the role says the engine's
`content_format` carries a `Langertha::Content::Image` in a shape the endpoint accepts (k267). A
true flag says **the selected `chat_model` sees the image**. A text-only model on a vision-capable
wire can accept the part and ignore it, so "the wire accepts it" would be true almost everywhere
and would tell a caller (knarr `/api/show`, a manifest) nothing.

The flag is resolved with the existing layers, per the llm-advisor table (docs only, 2026-09-25):

- **All-vision families** (OpenAI incl. OpenAIResponses, first-party Anthropic, Gemini, Hetzner)
  keep the role-derived flag. Layer-3 rows clear it for the text-only exceptions (legacy
  `gpt-3.5` / `gpt-4`, `o1-mini`, `claude-2`, `gemini-1.0-pro`, embedding and TTS ids).
- **Other cloud engines with known vision models** (DeepSeek, Mistral, XAI, MiniMax,
  MiniMaxAnthropic, Moonshot, Perplexity, Cerebras, Scaleway, TSystems, Groq) use the k209 shape:
  a `qr/\A/ => { image_input => 0 }` catch-all first row, then the documented vision ids
  re-assert it. An unknown id makes no claim. TSystems' rows match case-insensitively because its
  docs spell one model two ways (`qwen-3.6-35b-fp8`, `Qwen3.6-35B-A3B-FP8`). Groq has no default
  model and building its `chat_model` croaks, so its table is empty when no model is configured
  and an engine `around` clears the flag in its place. `supports()` keeps answering without a
  model, as it did before.
- **No claim engine-wide (layer 2):** gateways (OpenRouter, HuggingFace, Replicate), self-hosted
  servers (vLLM, VLLMHook, SGLang, LlamaCpp, Ollama, OllamaOpenAI, LMStudio, LMStudioOpenAI),
  the shims (MoonshotAnthropic, AKIAnthropic, LMStudioAnthropic), AKIOpenAI and NousResearch. The
  model behind them is not known to the client. AKI native does not compose the role: its wire is
  unverified.

The flag is **advisory**. No gate reads it: an image sent without the claim is serialized and
sent as usual, and the provider decides. Probing live model metadata (OpenRouter
`input_modalities`, Ollama `/api/show` capabilities, llama.cpp `/props`, LM Studio
`capabilities.vision`) would let the no-claim engines answer per model. That is follow-up work,
not part of this table. The DeepSeek (`deepseek-flash` = V4.1, vision since 2026-09-10) and
Mistral (`mistral-small-latest` = Small 4) rows rest on facts the advisor flagged as recent; they
were not re-verified, and the engine comments carry the date.

## Update (k270 — the gateway / self-hosted `image_input` no-claim moves to layer 3; a learned layer follows it)

The k266 Update put the no-claim of gateways and self-hosted servers in layer 2. It was never a
wire fact, only "the client does not know the model", and ADR 0032 adds a learned layer (facts
probed from the provider's own model metadata) that runs right after this table and must be able
to answer over it. On the engines that can probe (OpenRouter, Ollama, OllamaOpenAI, LMStudio,
LMStudioOpenAI, LlamaCpp) the `delete $caps->{image_input}` in the `around` is therefore a
catch-all row `qr/\A/ => { image_input => 0 }`; the other no-claim engines keep the layer-2
clear. Without a probe the answers are unchanged. The table walk now resolves `chat_model`
through `_capability_model`, which turns the croak of an engine without a default model
(OpenRouter, OllamaOpenAI) into "no model", matched as `''` like the k209 rule above.

## Update (k352 — a per-request `model` is not re-scoped; it warns when it flips a decision the request uses)

A `model` passed to `chat_f` or `chat_stream_realtime_f` is not a canonical control. It rides
`%extra` into the request builder and replaces the body's model field. Every model-scoped decision
still reads `chat_model`: this table and the learned layer (ADR 0032), a model-aware layer 2
(Gemini's `around`), the exclusion rules (ADR 0024), the reasoning profile (ADR 0023), the
temperature gate (ADR 0025), the per-model `tool_wire_format` (ADR 0033), and per-model body
details (the completion-length key, the k225 `response_size` default, native structured output).
Before this change, a Claude slug passed as the override on a Hermes-tagged NousResearch instance
silently got the Hermes prompt.

**Decision: warn, don't re-scope.** Re-scoping a request to its override would mean a second engine
per request. The override may also be intended. So
`Role::Chat::_warn_model_override` runs at the top of both methods, before any decision is taken.
It carps rather than croaks, and the request is sent unchanged.

- **Silent** when there is no override (undef, empty, a ref), or when the override equals
  `chat_model`. Neither case does any work.
- **Otherwise it compares two engines.** It evaluates the decisions on an in-memory clone with
  `chat_model => $override`, following the `Manifest::Builder::_capability_clone` pattern:
  `_reset_derived_tool_wire_format` re-resolves a builder-made tag and keeps a tag given to the
  constructor (ADR 0033). The clone's decisions are compared with those of the engine as configured.
- **Only decisions the request uses are compared.** An override that flips nothing on the wire
  stays silent. A capability flag is compared only when one of its request features is in play
  (`%CAP_CONSULTED_BY`). For example, `tool_choice_*` needs a `tool_choice`, and
  `response_format_json_schema` needs a `response_format` or a `tool_choice` (the ADR 0005
  rewrite). `cached_content` needs a bound cachedContent. `image_input` is never compared: it gates
  nothing (k266 Update above). **A flag missing from the table is always compared**, so a future
  model-scoped flag produces a warning instead of silence.
- **Engines add their own decisions** with an `around _model_scoped_wire_decisions`. NousResearch
  adds its reasoning prompt this way (when `reasoning` is on); DeepSeek adds its V3.2 `thinking`
  switch (when a reasoning control is set, k362). This hook is the extension point for
  any model-scoped decision taken outside the named hooks above.
- The warning names the flipped decisions. It is a per-request value, so it fires on every request
  (k247 convention), through `_langertha_carp`, so it points at the caller's line. If a decision
  cannot be computed (it dies inside the probe), the request goes on unwarned, and its own path
  reports the error.

`_check_capability_exclusions` now calls the new `_matched_capability_exclusions` (behavior
unchanged), so the warning compares the matched rule set for both models. Test:
`t/78_model_override_warning.t`.

**Known gaps.** A model-scoped decision that is taken inline, rather than through a named hook, is
not compared unless its engine names it through the `around`. `Engine::DeepSeek::reasoning_kwargs_for`
was such a case (it switches on `_is_deepseek_v3(chat_model)`, and every DeepSeek id resolves the
same reasoning profile); k362 closed it with the `thinking switch` decision.

**URL-routed wires (k357): route, don't croak.** Gemini (`models/{model}:generateContent`, both the
plain and the streaming route) and AKI native (`/api/call/{model}`) name the model in the URL, not in
the body. Before k357 the override rode `%extra` into the body as an unknown field while the URL
still named `chat_model`, so it never changed which model answered. Now
`Role::Chat::_url_model(\%extra)` takes `model` out of `%extra` and returns it for the URL, or
`chat_model` when there is no override (the same test as the warning: undef, empty or a ref is none).
This is the one `%extra` key these two engines consume instead of passing it through (ADR 0004): on
their wire, the URL is where the model field lives. The override now behaves as on every body-routed
wire (the model changes, the decisions stay with `chat_model`, the warning says so), which is the
normalize-don't-gatekeep reading. A croak would refuse on two engines what every other engine
accepts. A bound Gemini `cachedContent` does not block the routing: the cache is named in the body
and the model in the URL, as with `chat_model` (ADR 0035). Whether the server rejects a cache used with a
model other than the one it was created for is not verified here. That holds for a mismatched
`chat_model` as well, so no check was added for the override alone.

**`Langertha::Chat` (k360).** The wrapper's `model` attribute rides `%extra` into `chat_request`,
`chat_stream_request` and `build_tool_chat_request` without going through `chat_f`. Every Chat
entry point (`simple_chat`, `simple_chat_f`, `simple_chat_stream`, `simple_chat_with_tools`,
`simple_chat_with_tools_f`) now calls the engine's `_warn_model_override` itself, once per call, as
`Langertha::Chat-><method>`. It passes the features the call uses: the wrapper's `temperature`,
the gathered tools (the tool loops), streaming. The warning is the same function, not a copy, and
it is silent for an engine without it.

## Update (k344 — `image_input` now selects the tool-result image form)

The k266 Update said no gate reads `image_input`. That still holds for what a caller sends: an
image in a message is never blocked. But `Role::Tools::format_tool_results` now reads the flag to
choose how a *tool's* image output is represented (ADR 0001 k344 Update): with the claim, the
Responses and Gemini 3 wires carry it as an image part; without it, it stays the k336 text
placeholder. It is a representation choice for content the caller did not pick, not a block, and
an engine or model without the claim behaves exactly as before. The reverse is the cost: an
over-broad `image_input` claim is no longer harmless on the `responses` and `gemini` wires. If a
model that does not see images claims the flag, a tool that returns an image makes the next
tool-loop request carry an image part, which the provider may reject (a 400 mid-loop). The
layer-3 rows therefore matter for correctness there, not only for reporting. The ADR 0032 rationale for
learning `image_input` only ("advisory, does not change what is sent") is therefore slightly
weaker: a learned fact could now change a tool-result's form, but only on the `responses` and
`gemini` wires, and none of the engines that probe (ADR 0032) uses either.

## Update (k359 — the Anthropic wire reads `image_input` too; MoonshotAnthropic moves its claim to layer 3)

`format_tool_results` now reads the flag on the `anthropic` wire as well (ADR 0001 k359 Update):
a tool's image becomes an `image` block in the `tool_result` only with the claim, else the k336
placeholder. So the costs of the k344 Update now hold on three wires, and the no-claim of a shim
is no longer free. `MoonshotAnthropic` cleared `image_input` engine-wide in layer 2 (k266), which
would have kept its vision models — `kimi-k3` (the default), `kimi-k2.6`, `kimi-k2.7-code` and
`-highspeed`, all four ids its static model list names — from seeing a tool's screenshot. It now
carries `Engine::Moonshot`'s rows in layer 3: the `qr/\A/ => { image_input => 0 }` catch-all, then
`qr/\Akimi-k(?:3|2\.6|2\.7-code)(?!\d)/` re-asserts it for all four. Kimi's Messages schema
documents `image` blocks, `tool_result` included (docs only, 2026-09-30; not live-verified on this
face). `AKIAnthropic` keeps its layer-2 no-claim, and additionally keeps the placeholder through
`_tool_result_images_on_wire` even under a future claim. `LMStudioAnthropic`'s no-claim is a
layer-3 catch-all that a probed fact overrides (ADR 0032 k365): it is the first probing engine on
the `anthropic` wire, so with this change a learned `vision` picks the `image` block in the
`tool_result` there. That path is not live-verified: LM Studio does not document images in a
`tool_result`. The k344 remark on ADR 0032 (no probing engine on a request-changing wire) no
longer holds for this one engine.

## Update (k361 — `image_input` also selects the tool-result PDF form on OpenAI Responses and Gemini 3)

`format_tool_results` reads the flag for one more representation choice (ADR 0001 k361 Update): a
PDF a tool returned rides as an `input_file` part (OpenAIResponses) or a
`functionResponse.parts` `inlineData` part (Gemini 3) only when the model claims `image_input`,
and stays the k336 placeholder otherwise. The flag keeps its meaning ("the model sees images"):
both providers document PDF reading as a vision feature, so no new flag was made for it. The k344
cost widens accordingly — an over-broad claim on OpenAIResponses or Gemini 3 can now also put a
PDF part into a tool-loop turn for a model that cannot take it. Perplexity is unaffected (its
Agent API has no `input_file`; the engine's `_tool_result_pdf_on_wire` is 0).

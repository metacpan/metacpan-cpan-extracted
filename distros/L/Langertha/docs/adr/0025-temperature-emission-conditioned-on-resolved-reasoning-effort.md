# ADR 0025 — Temperature's wire emission is conditioned on the resolved reasoning effort (OpenAI reasoning models)

- Status: accepted
- Date: 2026-09-19
- Tags: reasoning, temperature, wire-format, capabilities, chat_f, model-scoped

## Context

OpenAI reasoning models (the o-series, the gpt-5 line except the non-reasoning `gpt-5-chat`, and
gpt-6) return **HTTP 400 on a non-default `temperature` while reasoning is active** — *"'temperature'
does not support 0.7 with this model. Only the default (1) value is supported"* (live-verified
2026-09-17 on `gpt-5.6-terra` + `gpt-5.6` against `/v1/chat/completions`). This is neither a flat
per-model capability nor a static wire fact:

- **It is effort-aware.** At `reasoning_effort=none` — where these models actually accept disabling
  reasoning — the *same* call returns 200 with the non-default temperature. So clearing the
  `temperature` capability wholesale (ADR 0002 / ADR 0019) would wrongly drop the valid `effort=none`
  path.
- **It fires on the no-effort path too**, because when the caller sets no effort the model's
  **server-side default effort** (medium) applies — reasoning is on — so the predicate must resolve
  the effort *including* that default.

`temperature` and `reasoning_effort` are two ADR 0009 quartet concerns. ADR 0009 placed each
concern's field in a **disjoint body key**, and the k133 Update recorded the first break of that
disjointness — two concerns *sharing* the `output_config` key. k155 is a **different** kind of
cross-concern interaction: not two concerns sharing a key, but **one concern's emission gated by
another concern's resolved value.** That is a new interaction the quartet had not yet had.

## Decision

Condition `temperature`'s wire emission on the resolved reasoning effort, in two pieces:

1. **A shared `_temperature_kwargs($controls)` gate in the OpenAI wire roles**
   (`Role::OpenAICompatible.pm:314`, `Role::ResponsesCompatible.pm:109`), which **all four OpenAI
   wire sites route through** (chat + stream on each role, replacing four copies of the inline
   `exists $controls->{temperature} ? … : has_temperature ? …` ternary). It mirrors
   `AnthropicCompatible::_temperature_kwargs` — the `supports('temperature')` check plus
   control-beats-attribute resolution — and adds the effort-aware drop: **only** a non-default value
   (`temp != 1`) under active reasoning is dropped, with a `carp` that names the escape hatch
   (`reasoning_effort => 'none'`). `temperature=1` passes through **silently** (dropping the wire
   default would be a pure-noise warning).

2. **An effort-aware, model-aware predicate `_temperature_rejected_by_reasoning($controls)` on
   `Engine::OpenAI`** (`OpenAI.pm:126`), consumed **read-only** by the gate via `can()`. The predicate:
   - **(a)** gates on the per-engine reasoning-model regex (`o\d` / `gpt-5` except `-chat` / `gpt-6`)
     — the ADR 0019 per-engine model list;
   - **(b)** resolves the effort control-beats-attribute, treating **unset as the server-side
     default** (reasoning on); and
   - **(c)** counts a `none` effort as "reasoning off" **only where the model's wire actually accepts
     `none` as the disable value** — a *read-only* consult of
     `Langertha::Reasoning::Profile->for_model($model)->effort_accepted_on($wire, 'none')` (ADR 0023,
     the same effort table the serializer uses). A model that cannot be disabled (gpt-6) drops a
     `none` effort server-side and keeps reasoning on, so temperature stays rejected there.

   `OpenAIResponses` inherits the predicate and runs it on the `responses` wire; every **other**
   OpenAI-compatible engine (and Perplexity, the other Responses consumer) never defines the
   predicate, so the `can()` guard leaves their temperature untouched.

## Rationale

- **A runtime predicate, not a static capability clear** (deliberately, cf. ADR 0019). A static clear
  cannot see the per-request `effort=none` escape — it would drop a temperature the model would have
  accepted. The rejection is a function of *this request's* resolved effort, so the check has to run
  per call.
- **The `temperature` capability is deliberately NOT cleared** — a *deliberate keep* (ADR 0002).
  Temperature is genuinely valid on these models at `effort=none`, so the capability is honestly
  present; the gate is a per-request emission decision, not a capability fact.
- **Drop + carp, not croak** (contrast ADR 0021). Temperature is an advisory sampling knob; dropping
  it under active reasoning loses nothing the caller actually needs — the reasoning answer is the
  point, and the wire default (1) is what the model uses anyway. So the request proceeds and the
  caller is warned, with the escape hatch named. ADR 0021 croaks instead because there *both*
  conflicting fields carry essential intent (dropping either discards half the request); here the
  dropped field is recoverable and non-essential.
- **The predicate reads the Profile read-only** (ADR 0023): effort wire-truth has exactly one home,
  and this gate consults it rather than re-encoding "which models accept `none`."

## Consequences

- **A new interaction category in the ADR 0009 quartet:** control-on-control conditioning — one
  concern's emission gated by another concern's *resolved* value (including a server-side default).
  Distinct from the k133 `output_config` key-sharing case; recorded so the next such interaction has
  a precedent.
- **Blast radius is exactly OpenAI reasoning models.** Non-reasoning OpenAI models (`gpt-4o`,
  `gpt-5-chat`) and every other OpenAI-compatible / Anthropic / Gemini engine never define the
  predicate, so the `can()` guard is a no-op for them and their temperature is unchanged.
- **The four wire sites now share one gate**, so the Anthropic and OpenAI `_temperature_kwargs`
  gates read as siblings (same `supports` + control-beats-attribute skeleton, different provider
  quirk bolted on).
- **Verified offline** (no live calls): `t/79_openai_temperature_reasoning_gate.t` covers both wires,
  the streaming path, and the drop/carp rule; `t/60_responses_requests.t` keeps its temperature
  assertion valid by pinning `reasoning_effort => 'none'`.

## Cross-links

- **Extends ADR 0009** — the request-side control quartet gains its first *control-on-control*
  conditioning, distinct from (and additional to) the k133 `output_config` key-sharing break.
- **Consumes ADR 0023** — reads `Langertha::Reasoning::Profile::effort_accepted_on` read-only to know
  where `none` truly disables reasoning.
- **Relates ADR 0019** — kept a runtime predicate rather than a static, per-model capability clear,
  because a static clear cannot see the per-request `effort=none` escape.
- **Relates ADR 0002** — the `temperature` capability is deliberately *not* cleared (valid at
  `effort=none`); this is a per-request emission gate, not a capability correction.
- **Contrast ADR 0021** — same "a relationship a boolean can't spell, resolved above the registry"
  shape, but drop-and-warn here vs. croak there, because temperature is recoverable where the
  ADR 0021 pair is not.

## Update (k185 — the no-effort path is per-model: `default_reasoning_off` replaces the blanket "no effort ⇒ reasoning on")

§Context's second bullet stated the gate *"fires on the no-effort path too, because when the caller
sets no effort the model's server-side default effort (medium) applies — reasoning is on."* That
blanket assumption is **false per model.** Live-verified 2026-09-19: the **gpt-5.1 / gpt-5.2 /
gpt-5.4** line defaults to reasoning **OFF** with no effort (`reasoning_tokens=0`), so a non-default
`temperature` is accepted there (HTTP 200) — dropping it would be wrong.

- **The gate now resolves the no-effort default per model, via ADR 0023.**
  `_temperature_rejected_by_reasoning` (`OpenAI.pm:130`), on its no-effort branch (`!defined $effort`,
  `:149`), consults the Profile's new **`default_reasoning_off`** signal (ADR 0023's k185 Update):
  `return 0` (temperature honored) where the model's default is reasoning-off, `return 1` otherwise.
  So gpt-5.1/5.2/5.4 keep a non-default temperature at no effort, while gpt-5.5/5.6, gpt-6, the
  o-series and legacy gpt-5 still drop it (their default *is* a reasoning level).
- **Everything else in the Decision is unchanged.** The reasoning-model regex gate (§Decision.2a), the
  control-beats-attribute effort resolution (2b), and the explicit-`effort=none` branch (2c) are
  exactly as recorded — `none` still disables only where `effort_accepted_on($wire,'none')` is true,
  so gpt-6 (not disablable) still keeps its temperature dropped. The single change is that the
  no-effort path no longer assumes reasoning-on universally; it reads the Profile.
- **This sharpens, does not overturn, the ADR.** The control-on-control shape — one concern's emission
  gated by another's *resolved* value including a server-side default (§Consequences) — stands; the
  resolution simply became honest that the default is model-specific, not a flat "medium." The
  ADR 0023 dependency (§Cross-links "Consumes ADR 0023") now spans two Profile reads —
  `effort_accepted_on` *and* `default_reasoning_off`. Verified offline:
  `t/79_openai_temperature_reasoning_gate.t` (the live matrix: 5.1/5.2/5.4 keep temp at no effort;
  o4-mini / gpt-5 / gpt-5.5 / gpt-5.6 / gpt-6-astra drop it; an explicit effort re-enables the drop;
  `effort=none` keeps temp where accepted).

## Update (k186 — the reasoning-model gate (§Decision.2a) reads the Profile, not an engine regex)

§Decision.2a's per-engine reasoning-model regex (`o\d` / `gpt-5` except `-chat` / `gpt-6`) is
gone. `_temperature_rejected_by_reasoning` now resolves the Profile first and returns `0`
(temperature kept) unless `$profile->is_reasoning_model` (ADR 0023's k186 Update). Now all three
of the gate's model-specific reads are on the same Profile: `is_reasoning_model`,
`default_reasoning_off` and `effort_accepted_on`. The classification is unchanged for every
previously-covered id: the o-series, gpt-5, gpt-5.N and gpt-6 are still reasoning; gpt-4o,
gpt-4.1, gpt-5-chat and unknown ids are still non-reasoning. The one intended change is the
dotted chat ids (`gpt-5.1-chat-latest`, `gpt-5.2-chat-latest`, `gpt-5.N-chat*`). The old
lookahead missed them and would have dropped their temperature. They are now non-reasoning and
keep it. The effort resolution (2b), the `effort=none` branch (2c) and the k185 no-effort branch
are unchanged. Verified offline: `t/79_openai_reasoning_model_classification.t`.

## Update (k214 — Kimi fixes temperature per model; a capability-cleared drop now carps)

Every current Kimi chat id fixes `temperature` server-side and answers any other value with HTTP
400 (`invalid temperature: only 1 is allowed for this model`). `kimi-k3` and
`kimi-k2.7-code(-highspeed)` take only 1.0; `kimi-k2.6` takes 1.0 with thinking and **only 0.6
without** (advisor 2026-09-25, `platform.kimi.ai/docs/api/models-overview.md` plus third-party
400 reports; documentation-derived, not live-verified). Two things follow, and neither is this
ADR's effort-aware predicate:

- **A static per-model clear, not a runtime predicate.** The Kimi rejection does not depend on
  reasoning effort, so it is an ADR 0019 layer-3 row on **both** faces (`Engine::Moonshot`,
  `Engine::MoonshotAnthropic`): `qr/\Akimi-k3(?!\d)/` and `qr/\Akimi-k2(?!\d)/` =>
  `{ temperature => 0 }`. OpenRouter's `moonshotai/kimi-*` is deliberately not matched.
- **"temperature=1 passes" does not carry over.** §Decision's rule that the wire default 1 always
  passes is correct for OpenAI, where 1 is always accepted. On Kimi it is wrong: `kimi-k2.6`
  without thinking 400s on 1. The capability clear therefore keeps the field off the wire for
  every value, 1 included. (Latent today, since nothing sends `thinking:{type:disabled}` on the
  OpenAI face, but live on `MoonshotAnthropic` once k215 maps `none` to `disabled`.)

The one shared change is in both `_temperature_kwargs` gates (`Role::OpenAICompatible`,
`Role::AnthropicCompatible`): when `supports('temperature')` is false and the caller set a
temperature (attribute or per-request control) other than 1, the gate now **carps**
(`dropping temperature=X -- model 'M' does not take a temperature`) instead of dropping silently.
A dropped 1 stays quiet, for the same noise reason as §Decision. This also covers the Claude
Opus 4.7+ / 5-series clear (k138), whose drop was silent until now. `Role::ResponsesCompatible`'s
gate is unchanged (no engine on that wire clears `temperature` per model today). Verified
offline: `t/79_kimi_temperature_gate.t`.

## Update (k220 — the Responses wire gate carps too; one message, naming the remedy)

`Role::ResponsesCompatible::_temperature_kwargs` now resolves the temperature before the
`supports('temperature')` check and carps the same way as the other two gates, so the three wire
roles are at parity: a capability-cleared, caller-set temperature other than 1 carps on every
request (no once-per-process suppression), 1 is dropped quietly. Still latent on shipped engines
(no responses-wire engine clears `temperature` per model); it fires once a layer-3 row does. The
message is now identical on all three roles and names the remedy:
`dropping temperature=X -- model 'M' does not take a temperature (rejected or fixed
server-side); unset temperature to silence this`. Verified offline:
`t/79_kimi_temperature_gate.t` (test engines clear the flag with a layer-3 row). The carp still
reports the frame `Carp` picks, not the caller's own frame; left as is.

## Update (k247 — drop warnings name the caller; engine-attribute drops warn once per instance)

Two defects in the drop+carp convention, shared by every capability drop that followed this ADR
(the three `_temperature_kwargs` gates, `Role::Chat::_gate_tool_choice` (k239),
`_parallel_tool_calls_kwarg` (k241), the hermes-wire `tool_choice` warnings (k231/k246) and the
k250 "engine response_format replaced" warning):

- **Location.** The carps fire in private helpers several Langertha frames below the caller, and
  `Carp` skips only one untrusted frame, so the message named a line in
  `Role/OpenAICompatible.pm`, `Role/Chat.pm` or `Engine/Ollama.pm`. They now go through one
  helper, `Role::Chat::_langertha_carp`, which marks every `Langertha`, `Moose`, `Class::MOP`,
  `Eval::Closure` and `Future` package on the current stack as `%Carp::Internal` for the duration
  of that one `carp` (`local` on a hash slice). A synchronous `chat_f` / `simple_chat_f` /
  `chat_request` call therefore reports the user's own line. `croak` is untouched: marking all
  Langertha packages internal globally would have moved every croak's location too. Under an
  event loop there may be no user frame; `Carp` then reports what it finds and never dies.
- **Frequency.** k220's "carps on every request" was right for a per-request value but noisy for
  an engine attribute, which is identical on every request and every `chat_with_tools_f`
  iteration. A drop whose value comes from an engine attribute now warns **once per engine
  instance per (warning kind, value)**; the seen-set is a private lazy `_warned_drops` HashRef on
  the instance (`init_arg => undef`), never a global, so a new engine warns again. A per-request
  value still warns every time; `tool_choice` has no engine attribute, so its drops always warn.
  The temperature key includes `chat_model`, as the message does.

Verified offline: `t/76_drop_warning_location.t` (location on OpenAI temperature, Ollama native
`tool_choice`, Gemini `parallel_tool_use`; once-vs-every-time counts),
`t/79_kimi_temperature_gate.t` (parity assertion updated to the new frequency).

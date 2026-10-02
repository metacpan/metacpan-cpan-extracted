# ADR 0023 — Per-model reasoning wire-truth is a typed Profile value object

- Status: accepted
- Date: 2026-09-16
- Tags: reasoning, value-objects, wire-format, capabilities, model-scoped

## Context

ADR 0009 made `Langertha::Reasoning` a per-format value object: `to_openai` /
`to_responses` / `to_anthropic` / `to_gemini` / `to_ollama` each **clamp** the normalized
`reasoning_effort` vocabulary to what their wire accepts and **place** it in the right body
region. But the per-model knowledge *inside* those serializers stayed untyped — ad-hoc
lookup hashes (`%OPENAI_MODEL_EFFORT`, `%ANTHROPIC_EFFORT`, `%GEMINI3_LEVEL`) and regex
predicates (`_is_gemini_25`, `_is_fable_class`, `_openai_effort_ok`) open-coded in
`Reasoning.pm`. Two concrete costs:

1. **No datatype carries what a level means.** Each new reasoning family is another table
   plus another regex, edited by hand, with nothing that says "this is what the wire accepts"
   as a first-class fact.
2. **Model-family boundaries are duplicated across three sites**, not one file: `Reasoning.pm`
   (`_is_gemini_25`), `Engine::Gemini`'s `around engine_capabilities` (the same `2.5` vs `3`
   regex, in the *capability* layer), and `Engine::DeepSeek`'s own V3.2/V4 predicate. The
   level-clamp tables were centralized in ADR 0009; the family regexes were not.

ADR 0019 already named `Reasoning::to_gemini_level` and `Reasoning::_is_fable_class` as
per-model gating living as open-coded branches — consolidation candidates alongside its
declarative `model_capability_corrections` table.

A red-team pass (advisor-verified 2026-09-16, spec §10) surfaced the linchpin fact that
reshapes the whole seam: **no major provider publishes an official reasoning-level →
token-budget mapping.** OpenAI and Anthropic effort is adaptive and undocumented; the only
numeric level→token formulas in the wild are OpenRouter's, explicitly labeled as OpenRouter's
own convention. Any level→token numbers in this library are therefore *invented*. The same
pass live-probed a second fact that breaks a standing invariant (spec §7, karr k176):
`gpt-5.6-terra` rejects `reasoning_effort=max` on Chat Completions (HTTP 400) but accepts
`reasoning.effort=max` on the Responses API (HTTP 200) — the two OpenAI wires **diverge** on
`max` for the same model, which `Reasoning.pm`'s "`to_openai`/`to_responses` share one gate
and can never diverge" comment asserted they never could.

## Decision

Per-model reasoning wire-truth is a typed, immutable Moose value object,
`Langertha::Reasoning::Profile`, resolved **most-specific-first** by
`Langertha::Reasoning::Profile->for_model($id)` (exact id → family regex → provider default,
never dies) and consumed by `Langertha::Reasoning`'s `to_*` serializers and `BUILD` gate. It
replaces the inline `%OPENAI_MODEL_EFFORT` / `%ANTHROPIC_EFFORT` / `%GEMINI3_LEVEL` hashes and
the `_is_gemini_25` / `_is_fable_class` / `_openai_effort_ok` predicates. `Reasoning` now holds
one lazy `_profile` and reads all per-model gating off it (`effort_accepted_on`,
`anthropic_effort_ok`, `gemini_level_for`, `fable_class`, `control`). Landed Phase 1 (commit
`c312baf`), **behavior-preserving** — the resolver reproduces every existing clamp exactly.

The load-bearing idea is a **three-category taxonomy with a firewall.** Reasoning knowledge
is not one thing; the original ticket's two-way split misclassified one category, and the
correction is the point of this ADR:

- **(a) Accepted vocabulary + native control type** — which levels the wire literally takes,
  and whether the control is `effort` / `budget` / `boolean` / `none`. Lives in the Profile
  (`control`, `levels`, `levels_by_wire`, `can_disable`, `disable_form`). This is the category
  that feeds the capability layer. Non-overridable: wire-truth.
- **(b) Provider-*enforced* numeric bounds & magic values** — Gemini 2.5's `thinkingBudget`
  floor/ceiling, `0`=off, `-1`=dynamic; Anthropic's per-generation `budget_tokens`
  availability. Lives in the Profile too (`budget_min`, `budget_max`, `off_value`,
  `dynamic_value`), each `source`-marked with a doc URL + verification date. **This is
  wire-truth, not convention** — an API rejects a value outside these bounds.
- **(c) Invented level↔budget interpolation** ("medium ⇒ N tokens") — no provider publishes a
  level→token table, so any such number is the library's own convention. Deferred to a
  `Langertha::Reasoning::BudgetPolicy` (Phase 2, sketch only; ships only when a consumer needs
  budget↔level conversion), clamped to the owning Profile's (b) bounds.

**The firewall rule: (c) may *read* (b) but can never *cross* it.** A curated convention must
be clamped to the Profile's enforced bounds so it can never emit a value the API rejects.
Putting (b) inside BudgetPolicy — as the original karr k173 ticket proposed — would let an
override silently violate a hard API bound. Reclassifying (b) as Profile wire-truth, out of
BudgetPolicy, is the single most important correction this design makes.

The registry is one ordered, most-specific-first table built lazily inside `Profile.pm`; each
entry carries a `source` receipt, so curating a new family is a single declarative add rather
than a new hash plus a new regex in `Reasoning.pm`. For the per-wire divergence the Profile
carries a `levels_by_wire` seam (per-wire refinement of `levels`, queried by
`effort_accepted_on($wire, $effort)`): Phase 1 populates `openai` and `responses` identically
to freeze current (shared, buggy) behavior; the `max` split is a Phase-1.5 data edit, not a
code change.

## Rationale

The value object owning both clamp and placement (ADR 0009) was right; what it lacked was a
datatype for the per-model facts it clamped against. Typing those facts turns "another family =
another table + another regex in three files" into "another declarative row with a source
receipt," and gives consumers one query surface (`for_model`) instead of scattered predicates.

**The linchpin is the (a)/(b)-vs-(c) firewall, and it exists because of provider reality, not
taste.** Advisor-verified 2026-09-16: no major provider publishes an official reasoning-level →
token-budget mapping (OpenAI/Anthropic effort is adaptive and undocumented; only OpenRouter
invents ratios, and labels them its own convention). So every level→token number is invention.
Invention that could emit an API-rejected value must be structurally prevented from crossing
wire-truth — hence the clamp-to-(b) firewall and hence (b) belongs to the Profile, never to the
convention layer.

**The per-wire seam exists because the wires demonstrably diverge.** Live-confirmed 2026-09-16
(spec §7, karr k176): `gpt-5.6` chat-completions 400s on `reasoning_effort=max` while the
Responses API accepts `reasoning.effort=max`. This refutes the old shared-gate invariant and
exposes a latent bug — the current `gpt-5.6` set includes `max` and is applied to *both* wires,
so `to_openai` emits a live-400 value. `levels_by_wire` is the shape that lets `to_openai` and
`to_responses` resolve different accepted sets; freezing them identical in Phase 1 keeps the
transform pure and characterization-locked (`t/47_openai_reasoning.t` stays green), and the
`max` split lands as a Phase-1.5 data edit citing that probe.

## Consequences

- **A new reasoning family** = one declarative Profile row (matcher, `control`, `levels`,
  optional (b) bounds, `source`), resolved by `for_model`, instead of a hash entry plus a regex
  predicate in `Reasoning.pm`. The `BUILD` budget-vs-effort gate now derives from
  `profile->control` (Gemini 2.5 is the only `control=budget` family today), so the family
  boundary is declarative, not an inline `_is_gemini_25` regex.
- **The capability layer was deliberately left untouched (relates ADR 0002).** The per-model
  level *subset* the Profile carries is finer than today's coarse `supports('reasoning_effort')`
  boolean, and is **not** projected into `engine_capabilities` — YAGNI: the Profile registry is
  queried directly for "which levels does model X accept," so wiring capability↔profile waits
  for a consumer that actually reads it. `thinking_budget` stays a dynamic flag set inside
  `Engine::Gemini`'s `around engine_capabilities` (it is **not** in `%ROLE_TO_CAPS`; a refactor
  that regenerated caps from the role registry would silently drop it and redden
  `t/65c_vllm_reasoning.t` / `t/78_engine_capabilities.t`). This is a **deliberate keep**, not
  an omission.
- **Acknowledged remaining drift, surfaced honestly:** `Engine::Gemini`'s `around
  engine_capabilities` still carries its own inline `/\Agemini-2\.5/` and `/\Agemini-3/`
  regexes. The family boundary is now declarative in the Profile for the *serialization* layer,
  but the *capability* layer was intentionally not migrated in Phase 1. This is a **candidate**
  future reconciliation — not a decided one, and it is the same consolidation ADR 0019 already
  parked for Gemini.
- **The ADR 0009 quartet is intact.** This decision types the per-model knowledge *inside* the
  reasoning value object; the role + value object + `reasoning_wire_format` tag + capability
  flag structure is unchanged. The ADR-0009 Update (`output_config` shared by two concerns via
  `_merge_output_config_format`) is **unaffected** — reasoning-effort placement did not move.
- **Ollama's direct construction path** (`Engine::Ollama`, which bypasses
  `Role::ReasoningEffort`) is pulled through the same Profile, so the boolean `options.think`
  collapse is now the `ollama` profile's `control=boolean` fact rather than a hand-coded branch.

## Future work

Phase 1.5 fixes are declarative Profile/`levels_by_wire` edits, each flipping exactly one
characterization assertion against a cited doc source — never folded into the behavior-preserving
refactor:

- **karr k176** — the OpenAI `max` per-wire split (chat drops `max`, responses keeps it) for the
  gpt-5.6 / gpt-6 generations, citing the live probe.
- **karr k174** — gate `gpt-5.1` (drop `minimal`/`xhigh`/`max`), with `gpt-5.1-codex-max` as a
  most-specific-first carve-out that re-adds `xhigh`.
- **karr k175** — Ollama level strings (`low`/`medium`/`high`/`max`) with GPT-OSS as a
  level-only discriminator, replacing the model-agnostic boolean.

Deferred beyond Phase 1.5:

- ~~**Phase 2 — `Langertha::Reasoning::BudgetPolicy`**~~ **— realized (k178).** See the closing
  Update. Category (c) + the inbound budget↔level bijection now ship as a real class; still
  consumer-driven and not default-shipped; every numeric output clamped to the owning Profile's (b)
  bounds (the firewall, enforced in code).
- **Gemini capability-layer consolidation** — migrate `Engine::Gemini`'s inline model-regex
  `around` into the declarative form. A candidate, not a defect; kin to the Gemini consolidation
  bullet in ADR 0019's *Future work*.

## Cross-links

- **Amends ADR 0009** — 0009 made `Langertha::Reasoning` a per-format value object with inline
  clamping + placement; this ADR types the per-model knowledge inside it into a Profile registry,
  keeping the per-concern wire-format quartet (role + value object + `reasoning_wire_format` tag +
  capability flag) intact. The 0009 `output_config`-sharing Update is unaffected.
- **Nuances ADR 0019** — 0019 named `Reasoning::to_gemini_level` / `_is_fable_class` as per-model
  gating living as open-coded branches; those now derive from the one declarative Profile table.
  The Gemini *capability*-layer `around` remains the un-migrated consolidation candidate 0019
  already flagged.
- **Relates ADR 0002** — the capability boundary above: the per-model level subset is finer than
  the role-derived `reasoning_effort` boolean and is deliberately not projected into
  `engine_capabilities`; `thinking_budget` stays a dynamic `around` flag outside `%ROLE_TO_CAPS`.
- Ground truth: the design spec
  `docs/superpowers/specs/2026-09-16-reasoning-profile-design.md`; Phase 1 commit `c312baf`;
  karr k173 (this decision). `CONTEXT.md`'s `reasoning_wire_format` / `Langertha::Reasoning` entry
  carries the vocabulary this ADR builds on (not restated here).

## Update (k178 — Phase 2 `BudgetPolicy` realized; the firewall is now enforced in code)

The deferred **Phase 2** category-(c) layer now exists as `Langertha::Reasoning::BudgetPolicy`
(`lib/Langertha/Reasoning/BudgetPolicy.pm`, k178) — the invented level↔token-budget interpolation and
its inbound inverse, with **the (a)/(b)-vs-(c) firewall enforced in code**, not merely asserted in the
design:

- **The firewall is a real clamp.** `_clamp` (`BudgetPolicy.pm:205`) pins every number to the owning
  Profile's category-(b) bounds (`profile->budget_min` / `budget_max`), and both directions run
  through it: `budget_for($level)` (`:250`) clamps its **output**, and `level_for($budget)` (`:299`)
  clamps its **input** before mapping it back to a level (a budget equal to the Profile's `off_value`
  maps to `none`). So category (c) may *read* the (b) bounds but can never emit a value the API
  rejects — the single most important correction this ADR made, now structural.
- **It is not a capability and is not default-shipped.** Nothing in Langertha wires it in; it exists
  only where a downstream consumer needs budget↔level conversion and constructs it explicitly
  (`for_model($id, %opts)` `:343`, mirroring the Profile constructor). It offers both an `explicit`
  form (curated `points` anchors) and a `range` form (a `linear`/`log` curve across the Profile's (b)
  bounds); the `source` receipt defaults to a string that says the numbers are **library convention,
  not wire-truth**. Category (a)/(b) stay in the Profile (its `levels` is empty for a budget control,
  keeping it pure wire-truth); the convention anchors live on the policy.
- This closes the ADR-0023 Phase-2 Future-work item; it does **not** change the Profile, the capability
  layer, or the ADR 0009 quartet. Verified offline: `t/48_reasoning_budget_policy.t` (firewall +
  bijection coverage).

## Update (k180 — self-hosted reasoning vocabulary is a Profile registry dimension)

Self-hosted engines (`vLLM` / `SGLang` / `llama.cpp`) get their accepted `reasoning_effort`
vocabulary from the **loaded model's chat template, not the server** — so the vocabulary is keyed
**per model-family**, exactly the category-(a) fact the Profile registry already types. k180 registers
the first such family without touching any code path:

- **Qwen3.x** is a declarative Profile row (`Profile.pm:490`, matcher `qr{(?:\A|/)qwen3\.\d}i` — with
  or without the HuggingFace `org/` prefix, since served ids look like `Qwen/Qwen3.8-27B-FP8`),
  `control => 'effort'`, `wire_format => 'openai'` (the sole wire these engines speak), accepting
  **`none|low|medium|xhigh`** and **dropping `high` and `minimal`** — live-probed 2026-09-17 on a
  cortex vLLM server (`Qwen/Qwen3.8-27B-FP8` 400s on `reasoning_effort=high`), receipt in
  `$QWEN_SELFHOSTED_SRC` (`Profile.pm:383`). The two rejected efforts drop before they can 400 the
  server.
- **Unknown self-hosted ids are deliberately *not* listed.** They fall through to the passthrough
  default and keep going **raw** — the correct posture for an unknown chat template ("correct the wire
  reality you can verify; don't invent one you can't"), consistent with the whole ADR-0023 stance.
- This is a new *dimension* of the same category-(a) registry, not a new mechanism: no capability
  wiring, no serializer change. Verified offline: `t/48_reasoning_profile.t` (the Qwen self-hosted
  matrix).

## Update (k185 — `default_reasoning_off`: the server-side default reasoning state is a category-(a) signal)

The Profile grew one more category-(a) wire-truth field beyond the
`control` / `levels` / `levels_by_wire` / `can_disable` / `disable_form` set §Decision enumerated:
**`default_reasoning_off`** (`Profile.pm:169`, `Bool`, default `0`). It records whether a model's
**server-side default effort** — the one that applies when *no* `reasoning_effort` is sent — leaves
reasoning **off**. Default `0` (the common case) means a bare request already reasons; `1` marks the
models whose no-effort default is non-reasoning: the **gpt-5.1 / gpt-5.2 / gpt-5.4** line returns
`reasoning_tokens=0` with no effort (live-verified 2026-09-19), set on those Profile rows
(`Profile.pm:495`, `:499`, `:511`).

- **It is category (a), not (b) or (c).** It is a fact about which state the wire presents by default
  — accepted vocabulary + native control type, non-overridable wire-truth — so it lives in the Profile
  alongside the other (a) fields, never in `BudgetPolicy`. It carries no numeric budget and cannot
  cross the firewall.
- **Distinct from `can_disable`.** `can_disable` answers *"does an explicit `none` effort turn
  reasoning off at all?"* (the disable **path**); `default_reasoning_off` answers *"is reasoning off on
  the **no-effort** path?"* (the default **state**). The two are separate facts queried at different
  points of the consuming gate, and a model can be one without the other.
- **Consumed read-only, by one gate.** `Engine::OpenAI::_temperature_rejected_by_reasoning` (ADR 0025)
  reads it on its no-effort branch to tell "reasoning active on the default path" apart from "no effort
  set" — the same read-only-consult-the-Profile discipline ADR 0025 already uses for
  `effort_accepted_on`. No serializer, no `for_model` resolution, and the deliberately-untouched
  capability layer all stay as recorded; this is a new declarative dimension of the same category-(a)
  registry, kin to the k180 self-hosted-vocabulary Update. Verified offline:
  `t/79_openai_temperature_reasoning_gate.t`.

## Update (k186 — `is_reasoning_model`: the OpenAI reasoning-model classification moves into the Profile)

The "is this an OpenAI reasoning model?" question used to be answered by an engine-side regex in
`Engine::OpenAI::_temperature_rejected_by_reasoning` (`\A(?:o\d|gpt-5(?!-chat)|gpt-6)`), a second
copy of model-family knowledge next to this registry. It is now a read-only Profile predicate,
**`is_reasoning_model`** (Bool, default `0`), and the engine regex is gone.

- **Explicit on both sides, conservative by default.** The curated OpenAI reasoning families (gpt-6,
  gpt-5.6, gpt-5.5, the gpt-5.1 pair, gpt-5.2/5.4, legacy gpt-5) carry `is_reasoning_model => 1`.
  Two new passthrough entries classify the uncurated lines without inventing a ladder: `\Agpt-5\.\d`
  (gpt-5.3, 5.7, ...) and `\Ao\d` (the o-series) are reasoning with the unlisted-id serialization.
  The non-reasoning models are marked explicitly: `\Agpt-4` (gpt-4o, gpt-4.1) with the
  unlisted-id serialization, and one chat carve-out per gpt-5 family (`gpt-5-chat`,
  `gpt-5.1-chat`, `gpt-5.[24]-chat`, `gpt-5.5-chat`, `gpt-5.6-chat`, plus a generic
  `gpt-5.N-chat`), prepended so they win over the family patterns. The provider default is
  `is_reasoning_model => 0`, so an unknown id never classifies as reasoning. Wrongly dropping a
  caller's temperature is the worse error.
- **Closes the dotted-chat lookahead gap.** The old `(?!-chat)` only saw a literal `-chat` directly
  after `gpt-5`, so `gpt-5.1-chat-latest`, `gpt-5.2-chat-latest` and any `gpt-5.N-chat*` were
  classified as reasoning. The carve-outs make them non-reasoning.
- **Classification only; the reasoning wire does not move.** Each chat carve-out is a clone of the
  family profile it sits in (`_non_reasoning_like`), with only `model_match`, `source` and the
  classification changed. The new passthrough entries have the same serialization fields as the
  default. `to_openai` / `to_responses` output is byte-identical for every single-digit id
  (`gpt-5.N-chat*`). Multi-digit chat ids (`gpt-5.10-chat`, …) do not exist yet and now resolve
  through the generic carve-out rather than a misread digit family, so their reasoning fields
  differ from before; the multi-digit family guard is karr #196. It is category-(a)
  wire-truth like `default_reasoning_off`. Only the OpenAI families are curated, so a `0` on a
  Claude, Gemini, Qwen or GPT-OSS profile means "not classified", not "known non-reasoning".
- Verified offline: `t/79_openai_reasoning_model_classification.t` covers reasoning,
  non-reasoning and dotted-chat ids on both OpenAI engines, the Profile predicate itself, and
  carve-out serialization parity. The pre-k186 table was green except for the dotted-chat rows,
  which were red.

## Update (k196 — multi-digit guard, per-digit chat carve-outs, default built first)

Three leftovers from the k186 review. The mechanism is unchanged; the registry got stricter about
digits and lost two hand-kept assumptions.

- **Dotted family patterns stop at one digit.** Every dotted pattern ends in `(?!\d)`:
  `gpt-5\.1`, `gpt-5\.[24]`, `gpt-5\.5`, `gpt-5\.6`, the uncurated `gpt-5\.\d` passthrough, the
  self-hosted `qwen3\.\d` and the bare `gemini-2\.5`. Before this, `gpt-5.10` resolved to gpt-5.1
  (reasoning, `default_reasoning_off`, the gated ladder) and `gpt-5.20` to gpt-5.2. A multi-digit
  id is not curated, so the k186 rule applies: it is an **unknown id**, resolves to the provider
  default, is non-reasoning (temperature kept) and gets the unlisted-id passthrough on every wire.
  The same holds for `gpt-5.1x`-style ids (`gpt-5.11` … `gpt-5.19`), `gemini-2.50` and `qwen3.10`.
  A letter suffix (`gpt-5.1-codex`, `gpt-5.5-pro`) still belongs to its family. Curating a
  two-digit generation later means adding its own row. The undotted `\Agpt-6` and `\Ao\d` rows
  carry the same `(?!\d)` guard, so `gpt-60` and `o10` are unknown ids while `gpt-6-astra`,
  `gpt-6.1` and `o3-mini` keep their families. k201 closes the gap after the dot: the `gpt-6` row
  becomes `\Agpt-6(?!\d)(?!\.\d\d)`, so `gpt-6.10` / `gpt-6.100` are unknown ids, while
  single-digit `gpt-6.N` deliberately keeps the full doc-sourced gpt-6 ladder (no `none`/`minimal`,
  chat `max` dropped) instead of a gpt-5-style uncurated passthrough row, which would send what
  the generation is documented to reject and would be shadowed by the gpt-6 row anyway.
- **Chat carve-outs are generated per digit.** The hand-written mapping (`gpt-5.[24]-chat` →
  gpt-5.2, a generic `gpt-5.\d+-chat` row → gpt-5.3) is replaced by `gpt-5-chat` → `gpt-5` plus
  one `gpt-5.N-chat` → `gpt-5.N` carve-out for each N in 0..9, each cloned from the profile its own
  family id resolves to. A newly curated gpt-5.N family is picked up by its chat ids without
  anyone editing the mapping. `gpt-5.10-chat` now matches no carve-out and resolves as an unknown
  id, which is also non-reasoning and serializes identically to the old generic row.
- **The provider default is built before the carve-outs.** A carve-out whose family id matches no
  row copies the default, so removing the `gpt-5\.\d` passthrough row no longer kills the
  registry at load time; the affected ids just degrade to unknown. Carve-outs resolve against the
  family rows only (`_match`), and the registry is assigned in one step.
- Verified offline: `t/48_reasoning_profile_single_digit_pin.t` replays a golden captured before
  the change (profile attributes plus the kwargs on all five reasoning wires for all seven efforts,
  for every single-digit gpt-5.N variant and a representative of every other row) and stayed
  green throughout. The multi-digit rows in `t/79_openai_reasoning_model_classification.t` and the
  passthrough-removal case in `t/48_reasoning_profile_registry_order.t` were red before the fix.
  The carve-out parity test now loops over the digits 0–9 on all five wires.

## Update (k208 — xAI grok rows: the first always-on family on the OpenAI wire)

`Engine::XAI` resolved every grok id to the unlisted-id passthrough, so `none`/`minimal`/`max`
reached `chat/completions` although xAI documents `low|medium|high|xhigh` for grok-4.6/4.7,
`low|medium|high` for grok-4.5, default `high`, and "reasoning cannot be disabled". Two rows now
carry that: `\Agrok-4\.[6-9](?!\d)` and `\Agrok-4\.5(?!\d)`, same set on the `openai` and
`responses` wires, `can_disable 0`, `disable_form 'absent'`. The mechanism is the existing one:
an effort outside the set drops (drop, not clamp), and the server default applies. The single-digit
point-release coverage follows the k201 gpt-6 precedent; the `(?!\d)` guard keeps
`grok-4.20-multi-agent`, whose effort field is an agent count, an unknown id. Source: the xAI
reasoning page (updated 2026-09-21), advisor-verified 2026-09-25 — documentation only; whether an
off-enum value 400s or is ignored is not live-verified.

## Update (k207 — Moonshot `kimi-k3` row; `can_disable 0` also covers an Anthropic-wire shim)

`qr/\Akimi-k3(?!\d)/` carries `levels [low high max]` on both OpenAI wires, `can_disable 0`,
`disable_form 'absent'`. The one row serves both Moonshot faces: `Engine::Moonshot` sends
`reasoning_effort` on `chat/completions`, and `Engine::MoonshotAnthropic` sends
`output_config.effort` through `anthropic_effort_ok`, which reads the same `levels`. Kimi's
Messages API has no `thinking` request field for K3, and `can_disable 0` is exactly what keeps
`to_anthropic` from sending one, so the Fable-class rule now applies to a non-Claude model too.
`medium`, `xhigh`, `none` and `minimal` drop on both faces and the server default `max` applies.
The match is `\A`-anchored on Moonshot's own ids: `moonshotai/kimi-k3` on OpenRouter is not
matched on purpose: what OpenRouter forwards for that id is not what Moonshot documents, and was
not checked, and the `(?!\d)` guard keeps `kimi-k30` an unknown id (k196). The K2.x line has no
row. Its flag is cleared per model on `Engine::Moonshot` only (ADR 0019 k207 update);
`MoonshotAnthropic` on K2.x still sends `output_config.effort` plus the adaptive `thinking` block,
as it did before k207, pending a check of what Kimi's Messages API takes there (karr k215).
Source: platform.kimi.ai `use-reasoning-effort`, `api/chat` and `api/messages`, advisor-verified 2026-09-25 — documentation only, not live-verified.

## Update (k209 — thinking-toggle rows: `thinking_on` + `disable_form 'thinking_disabled'`, serialized by `Reasoning`)

Three wires take a binary `thinking` object with an on/off `type` and no effort level:
MiniMax-M3 on `chat/completions` (`disabled|adaptive`, default `adaptive`), Kimi K2.x on
`chat/completions`, and Kimi K2.x on Moonshot's `/anthropic` Messages face (`disabled|enabled`;
`kimi-k2.7-code` accepts only `enabled`). The Profile could not express that: `control 'boolean'`
existed only descriptively for Ollama, `disable_form` was read by no serializer, and `to_openai`
/ `to_anthropic` could only emit an effort. The advisor proposed one shared extension; this
Update records it and the choice of where it is serialized.

- **Profile.** A new optional attribute `thinking_on` (enum `adaptive|enabled`, predicate
  `has_thinking_on`) marks a **thinking-toggle row** and names its on-type. A new `DisableForm`
  value `thinking_disabled` names the off-form `{type:'disabled'}`. `thinking_toggle_for($effort)`
  derives the object: `none` gives `{type:'disabled'}` when `disable_form` is `thinking_disabled`
  and nothing on a row that cannot disable (the field is omitted and the server default applies,
  the rule every always-on row already follows: Fable, grok, `kimi-k3`); any other level gives
  `{type: thinking_on}`. The level ladder collapses to on/off, so every level gives the same depth.
- **Rows.** `\AMiniMax-M3(?!\d)` (`can_disable 1`, `thinking_disabled`, `adaptive`) and
  `\AMiniMax-M2(?!\d)` (`can_disable 0`, `absent`, `adaptive`: M2.x accepts `disabled` but keeps
  thinking on). Both are `control 'boolean'` with no `levels`. The Kimi K2 rows land with k215.
- **Serialization in `Langertha::Reasoning`, not in engine overrides.** `to_openai` and
  `to_anthropic` return the toggle, and nothing else, when the resolved profile
  `has_thinking_on`. `display` rides along on an on toggle on the anthropic wire only; whether
  MiniMax and Kimi accept it there is unverified (it is a first-party Anthropic field, kept
  because `MiniMaxAnthropic` already sent it before k209). The
  advisor and the k209 brief suggested an engine-scoped `reasoning_kwargs_for` on
  `Engine::MiniMax` (the DeepSeek precedent). That was rejected as the larger design. It would
  need one override per engine (MiniMax, MoonshotAnthropic, later Moonshot) that repeats the same
  per-model regexes, and this ADR moved that per-model truth out of code and into the Profile. A
  replacing `reasoning_kwargs_for` also bypasses the role's ADR 0009 k204 `supports()` gate, as
  DeepSeek's comment warns. With the branch in `Reasoning`, the engines add only capability rows
  and the k204 gate stays the role's.
- **The toggle is opt-in per endpoint (review I1).** The `thinking` object is the spelling of
  MiniMax's cloud API and Kimi's Messages face, not a property of the model: a self-hosted vLLM /
  SGLang / llama.cpp server, an OpenAI-compatible proxy or another `/anthropic` shim serving a
  bare `MiniMax-M3` or `kimi-k2.6` id does not parse it. An engine opts in with
  `sub _reasoning_thinking_toggle { 1 }` (`Engine::MiniMax`, `Engine::MiniMaxAnthropic`,
  `Engine::MoonshotAnthropic`; `Engine::Moonshot` since k219). `Role::ReasoningEffort`
  passes that as `Reasoning->new(thinking_toggle => 1)`, and `Reasoning`'s profile resolution
  hides a toggle row from every Reasoning without it: the id resolves to the unlisted-id
  default, so every other engine sends byte-for-byte what it sent before k209 (pinned by
  `t/48_reasoning_thinking_toggle_scope.t` against bodies generated from 4e7f9d8, and by
  foreign-engine rows in the t/47 golden). An engine predicate was chosen over a dedicated
  `reasoning_wire_format` value to keep ADR 0009's tag set clean: the tag names the envelope a
  reasoning field is placed in (`openai`, `anthropic`, ...), and the toggle occurs inside two of
  them, so a tag would need an `openai`×toggle and an `anthropic`×toggle variant, and every
  existing `to_openai`/`to_anthropic` fallback for the engine's non-toggle ids (`kimi-k3` on
  `MoonshotAnthropic`) would have to be re-dispatched from the new tags. The predicate is one
  orthogonal bit on the one wire tag the engine already declares, the same shape as
  `_native_structured_output` (ADR 0005) and `_temperature_rejected_by_reasoning` (ADR 0025).
  The rows are also `\A`-anchored on the providers' own ids, so aggregator ids
  (`minimax/minimax-m3`, `moonshotai/kimi-*`) never match a toggle row either.
- **Consequences.** `Engine::MiniMax` re-enables `reasoning_effort` for M3 only (ADR 0019 k209
  Update). `MiniMax-M3` gets `{type:'disabled'}` for `none` and `{type:'adaptive'}` for every other
  level on `chat/completions`, where nothing was sent before. The same rows now reach
  `Engine::MiniMaxAnthropic` too: on M3, `none` sends an explicit `{type:'disabled'}` (it matches
  the endpoint default, so the effect is unchanged), and `minimal` turns thinking on (`adaptive`)
  on M3 and M2.x, as in MiniMax's own `/v1/responses` mapping. That endpoint's k209 `output_config`
  strip (ADR 0009) stays, and it is now a no-op on the toggle rows. As with `kimi-k3`, a
  `thinking_budget` on MiniMax-M3 now croaks in `Reasoning::BUILD` where it was dropped silently
  before. Source: platform.minimax.io `openapi-chat-openai.json`, `openapi-chat-anthropic.json`,
  `openapi-responses.json`, advisor-verified 2026-09-25. This is documentation only and not
  live-verified. Pinned by `t/48_reasoning_thinking_toggle.t` and the regenerated
  `t/47_reasoning_capability_gate.t` golden rows.

## Update (k215 — Kimi K2.x toggle rows on `MoonshotAnthropic`; supersedes the k207 note's "still sends")

The k207 Update left `MoonshotAnthropic` sending `output_config.effort` and an `adaptive`
`thinking` block on K2.x. Kimi's Messages API documents `output_config.effort` for `kimi-k3` only.
On K2.x the endpoint parses `thinking.type` (Claude Code guide): `kimi-k2.7-code` accepts only
`enabled` ("400 invalid thinking: only type=enabled is allowed for this model"), `kimi-k2.6`
takes `enabled|disabled`, and `adaptive` is undocumented for Kimi. Two k209 thinking-toggle rows
now carry that:

- `qr/\Akimi-k2\.7-code(?:-highspeed)?\z/`: `thinking_on 'enabled'`, `can_disable 0`,
  `disable_form 'absent'`. Every level sends `{type:'enabled'}`. `none` omits the field, as on
  every row that cannot disable, and the server keeps thinking on. **Unverified:** that the
  endpoint accepts a k2.7-code request with no `thinking` field at all (the Claude Code guide
  only says thinking *off* is rejected); if omission 400s, bare requests without any reasoning
  control are broken too, and the fix belongs on the bare path. The brief asked for
  `enabled` to be sent always. It is sent for every level. For `none` it is omitted, because an
  omitted field on this model is exactly what a request without any reasoning control sends.
- `qr/\Akimi-k2\.6\z/`: `thinking_on 'enabled'`, `can_disable 1`, `disable_form
  'thinking_disabled'`. `none` sends `{type:'disabled'}`; any other level sends `{type:'enabled'}`.

Neither row has `levels`, so no `output_config.effort` goes out. The rows are `\z`-anchored to
Kimi's documented ids so that AKI.IO's hosted `kimi-k2.7-code-1100b` on `AKIAnthropic`, which is
another provider's API, keeps its previous wire. `MoonshotAnthropic` clears `reasoning_effort` for
every K2 id (`qr/\Akimi-k2(?!\d)/`, the same row as `Engine::Moonshot`) and re-enables it for the
two documented ids, the ADR 0019 k209 opt-back pattern. The sunset `kimi-k2.5` and the dash-form
`kimi-k2-thinking` therefore send nothing on this face. `Engine::Moonshot` still clears
`reasoning_effort` on K2, so the rows reach nothing on `chat/completions` there. Turning the
chat-face toggle on is a one-row capability change, left as future work.

**Unverified:** `display` on these toggles (see the k209 Update). Anthropic's own spec requires
`budget_tokens` with `type:'enabled'`, and
Claude Code sends one. Whether Kimi's endpoint requires it is undocumented. No `budget_tokens`
is sent. If a live check shows it is required, the fix is a budget on the toggle's on-form, not a
new mechanism. Source: platform.kimi.ai `docs/api/messages.md` and
`docs/guide/claude-code-kimi.md`, advisor-verified 2026-09-25. This is documentation only; no
live call was made. Pinned by `t/48_reasoning_profile_moonshot.t` and the `t/47` golden rows
for `MoonshotAnthropic` on `kimi-k2.6` and `kimi-k2.7-code`.

## Update (k219 — the Kimi K2 toggle rows reach `chat/completions` through `to_openai`, unchanged)

`Engine::Moonshot` now defines `_reasoning_thinking_toggle`, which completes the list in the
k209 Update. Kimi's `chat/completions` takes the K2.x toggle as a top-level `thinking` object with
the same `type` values as the Messages face. On `kimi-k2.6`, `none` sends `{type:'disabled'}` and
any other level sends `{type:'enabled'}`. Neither `keep`, `reasoning_effort` nor `temperature` is
sent.

The Profile and the serializers needed no change. The two Kimi K2 rows declare
`wire_format 'anthropic'`, but `wire_format` is descriptive and not the dispatch key (see the
attribute's POD). `to_openai` already returns `_thinking_toggle` for any `has_thinking_on` row
once the endpoint has opted in. On the openai wire the toggle never carries `display`, and
the object that comes out, `{type}` alone, is the one the chat schema asks for:
`additionalProperties: false`, `type` required, and `keep` left out, as the advisor recommends.
The rows keep `wire_format 'anthropic'`. MiniMax's rows already serve both wires under `openai`,
so the attribute was never a per-wire claim for toggle rows.

`kimi-k2.7-code` resolves to its row on this engine as well, but the capability layer keeps its
`reasoning_effort` cleared (ADR 0019 k219 Update). The k204 gate therefore sends nothing there,
and that is the documented path on this face. The k215 Update's open question, whether a
k2.7-code request with no `thinking` field is accepted, is answered for `chat/completions`: every
documented k2.7-code example omits it. For `/anthropic` it is still unverified. `kimi-k3` has no
toggle row and keeps its `reasoning_effort` (k207). `MoonshotAnthropic` is unchanged.
Source: platform.kimi.ai `docs/api/models-overview.md`, `docs/api/chat.md`,
`docs/guide/use-thinking-models.md`, the K2.6 and K2.7-code quickstarts, advisor-verified
2026-09-25. This is documentation only and not live-verified. Pinned by
`t/48_reasoning_profile_moonshot.t` and the `Moonshot|kimi-k2.6` rows of the `t/47` golden.

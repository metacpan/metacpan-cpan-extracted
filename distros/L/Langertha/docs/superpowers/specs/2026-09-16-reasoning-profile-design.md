# Design Spec — Reasoning Profile as a typed datatype (karr #173)

- Status: **draft for owner review** (all points resolved; #176 live-confirmed)
- Date: 2026-09-16
- karr: #173 (this) · drift surfaced: #174 (gpt-5.1 gate), #175 (Ollama levels), #176 (max divergence — **blocks §7**)
- ADRs touched: amends **0009** (value-object internals), nuances **0019** (model-scoped gating). New ADR is Phase 3.
- Advisor red-team: provider reality verified against docs 2026-09-16 (see §"Provider ground truth").

## 1. Problem & scope

Reasoning model knowledge in `Langertha::Reasoning` is untyped: ad-hoc `%HASH`
lookups (`%OPENAI_MODEL_EFFORT`, `%ANTHROPIC_EFFORT`, `%GEMINI3_LEVEL`) plus
regex predicates (`_is_gemini_25`, `_is_fable_class`). Two concrete costs:

1. **No datatype carries what a level means.** Each new model family = another
   table + another regex, edited by hand.
2. **Model-family boundaries are duplicated across three sites** (not just one
   file, as first assumed): `Reasoning.pm` (`_is_gemini_25`), `Engine::Gemini`'s
   `around engine_capabilities` (the same `2.5` vs `3` regex, in the capability
   layer), and `Engine::DeepSeek`'s own V3.2/V4 predicate. The *level clamp
   tables* are centralized; the *family regexes* are not.

**Goal:** a typed, per-model/family **Reasoning Profile** that IS the definition
of a model's reasoning wire-truth, from which both the `to_*` serializers and
(later) the capability layer derive. Outbound now; bidirectional (inbound
budget→level, bool→level) later as a consumer-driven increment.

**Non-goals / migration:** existing `to_*` wire output for models covered today
stays behavior-identical through the refactor (Phase 1). No new wire fields an
engine does not accept. The three known-wrong behaviors (#174/#175/#176) are
fixed **after** the behavior-preserving transform (Phase 1.5), each as an
isolated, doc-sourced change — never folded into the refactor.

## 2. The three-category taxonomy (the spine of this design)

The advisor red-team confirmed the linchpin: **no provider publishes an official
reasoning-level → token-budget mapping** (OpenAI/Anthropic effort is adaptive and
undocumented; the only numeric formulas in the wild are OpenRouter's, explicitly
labeled as OpenRouter convention). So level→token numbers in a library are
invented. This forces a **three-way** split — the ticket's original two-way split
misclassified one category:

| Cat | What | Home | Overridable? |
|---|---|---|---|
| **(a)** | Accepted vocabulary + native control type (which levels the wire literally takes; effort / budget / boolean) | **Profile** → feeds capability | No — wire-truth |
| **(b)** | Provider-**enforced** numeric bounds & magic values (Gemini 2.5 `128`/`32768`/`0`=off/`-1`=dynamic; Anthropic `budget_tokens` availability, which is per-generation) | **Profile** (`source`-marked) | No — wire-truth |
| **(c)** | **Invented** level↔budget interpolation (e.g. "medium ⇒ N tokens") | **BudgetPolicy** (Phase 2) | Yes — convention |

**Firewall rule:** (c) may *read* (b) but can never *cross* it. A curated
BudgetPolicy override must be clamped to the Profile's (b) bounds so a convention
can never emit a value the API rejects. Putting (b) in BudgetPolicy — as the
original ticket proposed — would let an override silently violate a hard API
bound. That is the single most important correction in this spec.

## 3. Data types

### `Langertha::Reasoning::Profile` (Phase 1) — categories (a) + (b)

Immutable Moose value object. `ReasoningLevel` is a real enum subtype defined
**once** in a shared type module and reused (redefining an enum name croaks).

```
ReasoningLevel = enum[ none minimal low medium high xhigh max ]   # ascending

# (a) wire-truth vocabulary + control
model_match   : Str | RegexpRef        # exact id or family pattern
control       : enum[ effort budget boolean none ]
levels        : ArrayRef[ReasoningLevel]   # accepted on-spectrum set, ascending
can_disable   : Bool                   # Fable/Mythos-class: 0 (thinking always on)
disable_form  : enum[ absent explicit_none think_false budget_zero ]
wire_format   : enum[ openai responses anthropic gemini ollama ]

# (b) wire-truth numeric bounds & magic values (only where control=budget)
budget_min    : Maybe[Int]
budget_max    : Maybe[Int]
off_value     : Maybe[Int]             # gemini flash/flash-lite: 0 ; pro: undef (cannot disable)
dynamic_value : Maybe[Int]             # gemini: -1
source        : Str                    # doc URL + date — the curation receipt
```

`levels` means strictly "what the wire accepts" and is **empty** for
`control=budget`/`boolean`. Consumer quantization anchors do NOT live here (they
belong to BudgetPolicy) — keeping `levels` a pure wire-truth statement is what
holds the (a)/(c) firewall.

### `Langertha::Reasoning::BudgetPolicy` (Phase 2 — deferred, sketch only)

Category (c) only. Optional, ships only where a consumer (knarr #13) needs
budget↔level conversion. Carries the invented interpolation (`form: range|explicit`,
`curve`, `points`) and the **inbound** bijection: `budget_for($level)`,
`level_for($budget)`, `default_bool_level`. Every numeric output is clamped to the
owning Profile's (b) bounds. Explicitly flagged "convention, not wire-truth" with
a `source` honest about being empirical. **Not** a capability; **not**
default-shipped for effort providers.

## 4. Registry / resolution

`Langertha::Reasoning::Profile->for_model($id)` — one ordered resolver, matched
**most-specific-first**: exact id → family prefix/regex → provider default. It
replaces the scattered regexes with a single declarative table where each profile
carries `source` + date, so curating a new family is a single-file add (mirrors
the capability-registry principle).

The resolver must **reproduce today's clamps exactly** — this is the
regression-critical part:
- OpenAI generation ladder incl. the `gpt-5(?![.\d])` negative-lookahead
  (legacy gpt-5 must not swallow gpt-5.5/5.6).
- Gemini 3 clamp order (`3.7/3.8-flash` and `3.1-pro` drop `minimal`; `3-pro`
  is `low|high`; `3-flash`/`3.5`/`3.6`/`*-flash-lite` keep `minimal..high`).
- Carve-outs the resolver's ordering must express: **gpt-5.1** (base) vs
  **gpt-5.1-codex-max** (adds `xhigh`) — Phase 1.5, #174; **Ollama GPT-OSS**
  (level-only, ignores boolean) vs other Ollama models — Phase 1.5, #175.

## 5. How `Reasoning.pm` consumes the profile

`to()` resolves the profile via `for_model`, clamps/drops through
`profile->levels`, and picks the wire form via `profile->control` +
`profile->wire_format`. The `BUILD` gates (effort/budget mutually exclusive;
budget only where `control=budget`) derive from the profile instead of
`_is_gemini_25`. **Ollama's direct construction path** (`Engine::Ollama.pm:247`,
`:484`, which bypasses `Role::ReasoningEffort`) is pulled through the same
profile.

## 6. Capability boundary — what Phase 1 does NOT touch

The per-model **level subset** is finer than today's coarse
`supports('reasoning_effort')` boolean (derived from role composition, ADR 0002).
Phase 1 leaves the capability layer **entirely alone**:

- `thinking_budget` is **not** in `%ROLE_TO_CAPS`; it exists only as a dynamic
  flag set/cleared inside `Engine::Gemini`'s `around engine_capabilities`. A
  refactor that regenerated caps from the registry would silently drop it (and
  redden `t/65c_vllm_reasoning.t`, `t/78_engine_capabilities.t`). So the `around`
  stays as-is.
- No level-subset is projected into `engine_capabilities` (YAGNI). The Profile
  registry *is* the source for "which levels does model X accept"; fine-grained
  queries go through it directly. Wire capability↔profile together only when a
  consumer actually reads it.

## 7. OpenAI `max` — per-wire axis (DIVERGENCE CONFIRMED, #176)

Live-probed 2026-09-16 on `gpt-5.6-terra` (two requests, Getty-approved):
- Chat Completions `reasoning_effort=max` → **HTTP 400**: *"'reasoning_effort'
  does not support 'max' with this model. Supported values are: 'none', 'low',
  'medium', 'high', and 'xhigh'."*
- Responses API `reasoning.effort=max` → **HTTP 200**, `reasoning.effort:"max"`
  accepted.

**The wires diverge on `max` for the same model.** This refutes `Reasoning.pm`'s
"`to_openai`/`to_responses` share one gate and can never diverge" invariant, and
exposes a latent bug: the current `%OPENAI_MODEL_EFFORT{'gpt-5.6'}` includes
`max` and is applied to BOTH wires, so `to_openai` emits `reasoning_effort=max`
for gpt-5.6 → a live 400. `t/47_openai_reasoning.t` currently asserts that buggy
chat-wire behavior.

**Design consequence:** the OpenAI profile carries a **per-wire refinement at the
top of the ladder**. Confirmed sets for the gpt-5.6 generation:
- chat (`to_openai`): `none, low, medium, high, xhigh` — **no `max`**
- responses (`to_responses`): `none, low, medium, high, xhigh, max`

The same Responses-only-`max` pattern applies to gpt-6 per the doc (advisor Azure
mirror); curated in Phase 1.5, no further probe spend.

Shape (Phase 1): the profile type gains an optional per-wire level view
(`levels_by_wire`, defaulting to the shared `levels`) so `to_openai` and
`to_responses` resolve different accepted sets. **Phase 1 keeps current (shared,
buggy) behavior** — characterization-locked, `t/47` stays green — a pure
transform. **Phase 1.5** populates the split (chat drops `max`), flipping the
`t/47` chat-`max` assertion with this probe as the cited source. Tracked in #176.

## 8. Phasing

- **Phase 0** — resolve #176 live (approved). Determines §7.
- **Phase 1** — `Profile` + `for_model` + rewire `Reasoning.pm`/`BUILD` + Ollama
  direct path. **Behavior-preserving.** Capability layer untouched.
  Characterization tests first.
- **Phase 1.5** — the fixes as declarative profile edits, each flipping one
  characterization assertion with a doc source: #174 (gpt-5.1 gate + codex-max),
  #175 (Ollama level/GPT-OSS), Anthropic `xhigh` non-uniformity (Opus/Sonnet 4.6
  support `max` but not `xhigh`).
- **Phase 2** — `BudgetPolicy` (category c + inbound), consumer-driven, only when
  knarr #13 needs it.
- **Phase 3** — ADR recording the Profile VO + the three-category firewall.

## 9. Testing

Behavior is locked by a **characterization matrix (model × effort → wire kwargs)**
captured *before* touching internals. Most guards already exist and must stay
green unchanged through Phase 1:

- `t/47_openai_reasoning.t` — Chat==Responses ladder identity per model gen.
- `t/46_gemini_requests.t` — Gemini 3 clamp ladders, 2.5 integer budget, the
  conflict croaks (effort+budget; budget on non-2.5).
- `t/47_deepseek_reasoning.t` — V4 flat vs V3.2 `thinking:{type:enabled}` dispatch.
- `t/79_anthropic_wire_drift.t` — the `thinking.display` branch.
- `t/65c_vllm_reasoning.t`, `t/78_engine_capabilities.t` — reasoning capability
  flags incl. `thinking_budget` presence/absence.
- `t/78_capability_registry.t` — `Role::ReasoningEffort` stays classified.

Phase 1.5 fixes each add/flip exactly one assertion, with the doc source cited in
the test and commit. Live guards (`t/86`, `t/88`) stay key/server-gated.

## 10. Provider ground truth (advisor-verified 2026-09-16)

- **Linchpin:** no official level→token table (OpenAI, Anthropic). Budgets are
  invention → category (c).
- **Gemini 2.5 (b):** pro `128..32768` (cannot disable), flash `0..24576`
  (`0`=off), flash-lite `512..24576` (`0`=off); `-1`=dynamic; unset=auto ≤8192.
  Note: on the newer API surface Google is folding 2.5 into `thinking_level` —
  the profile should encode the **API-surface** split, not just model generation.
- **OpenAI ladders confirmed** for gpt-6/5.6/5.5/5; **gpt-5.1 is now gated**
  (#174). **`max` is Responses-only** for gpt-6/5.6 — chat 400s on `max`
  (live-confirmed 2026-09-16), driving the §7 per-wire axis (#176).
- **Gemini 3 clamps confirmed** exactly as coded.
- **Anthropic:** effort `low..max`; Fable/Mythos always-on (confirmed); but
  `budget_tokens` availability is **per-generation** (only-mode on 4.5-era,
  deprecated-but-works on 4.6, 400s on 4.7+) and `xhigh` is **not uniform**
  (Opus/Sonnet 4.6 have `max` but not `xhigh`) → per-model profile fixes the flat
  map's drift.
- **Ollama:** no longer boolean-only — accepts level strings; GPT-OSS ignores
  boolean and requires a level (#175).

## 11. The ticket's 5 open questions — resolved

1. **`none` (absent vs enum value):** both. `none` is a `levels` entry where the
   wire takes the literal string (OpenAI gpt-5.6); `disable_form` is the general
   off-switch. Orthogonal.
2. **BudgetPolicy owner (profile/engine/both):** profile default; per-engine
   override only when a consumer needs it (YAGNI) — model the merge seam, don't
   build it.
3. **curve log vs linear:** premature — only exists for category (c)/Phase 2.
   Gemini 2.5 is a direct int. If ever needed: log.
4. **`levels` empty for budget/boolean:** yes. `levels` = "what the wire
   accepts". Quantization anchors live in BudgetPolicy.
5. **profile per id or family:** family default + id overrides, most-specific-first.

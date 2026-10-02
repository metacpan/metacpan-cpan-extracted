# ADR 0024 — Pairwise capability exclusions become model-scoped: the `model_capability_exclusions` table

- Status: accepted
- Date: 2026-09-19
- Tags: capabilities, tools, structured-output, chat_f, streaming, model-scoped
- Supersedes: **ADR 0021** (mechanism only — its premise is reaffirmed)

## Context

ADR 0021 shipped the pairwise-exclusion guard — combining `tools` and a structured-output
`response_format` in one request body is rejected by some providers with an opaque HTTP 400, and no
boolean capability flag can express a constraint *between two* flags — as a **per-engine** hook,
`Langertha::Role::Chat::_check_capability_exclusions`, a base no-op overridden only on
`Engine::Cerebras` and `Engine::Groq`. ADR 0021's own *Future work* explicitly parked the model-scoped
generalization for the maintainer and named the exact defect the engine scope leaves open:

- The constraint is really a property of the **model**, not the engine: `gpt-oss-120b` and similar
  constrained-decoding stacks reject `tools` + a `json_schema` `response_format` because the
  grammar-constrained decoder and the tool-call grammar are mutually exclusive.
- So the 400 goes **uncaught wherever that model is reached through an engine with no override** — the
  `TSystems` / `AKIOpenAI` gpt-oss defaults, and the aggregator routes (`OpenRouter` / `HuggingFace` /
  `Replicate`) that resolve to a `.../gpt-oss-` backend id.
- And a per-engine guard cannot self-correct if a provider later relaxes the limit for one model.

This is the same engine→model axis move that turned ADR 0002 into ADR 0019 for the boolean
*corrections*; k148 makes it for the pairwise *exclusions* ADR 0021 introduced.

## Decision

Replace ADR 0021's per-engine hook with a **per-model exclusion table**,
`Langertha::Role::Chat::model_capability_exclusions` (`Chat.pm:494`), that **mirrors ADR 0019's
`model_capability_corrections`**: an **ordered list of `( $matcher => $rule )` pairs keyed on
`chat_model`**, `$matcher` an exact model-id string (matched with `eq`) or a `qr//` family regex
(matched against `chat_model`), walked by the same splice loop with later entries able to be the last
word. The one structural difference is the **payload**: where a correction carries a declarative
`{ cap => 0|1 }` override, an exclusion carries a **coderef** — the concrete seam, **deliberately not
a declarative constraint DSL**.

`_check_capability_exclusions` (`Chat.pm:502`) becomes the per-model iterator: for the selected
`chat_model` it invokes each matching rule as `$self->$rule(%request)` with `has_tools` /
`response_format` / `streaming`, and each rule croaks on the combination its model rejects. It is
consulted **unchanged in placement** from `chat_f` (`Chat.pm:613`, `streaming => 0`) and
`chat_stream_realtime_f` (`Chat.pm:779`, `streaming => 1`), still **after** the ADR 0005
forced-named-tool rewrite — so a request ADR 0005 already collapsed to a single-path body still
pre-empts the guard.

The rules move to where the constraint actually lives:

1. **The shared gpt-oss rule lives on `Engine::OpenAIBase`** (`OpenAIBase.pm:113`,
   `model_capability_exclusions` returning `qr/gpt-oss/ => \&_exclude_tools_with_json_schema` at
   `:119`). Because it is declared on the shared OpenAI-dialect base, **every OpenAI-dialect engine
   inherits it**, so the constraint travels with the model — caught on the Cerebras direct route, the
   TSystems / AKIOpenAI gpt-oss defaults, and the aggregator routes — with no per-engine plumbing.
   The rule fires only on `has_tools` + a `json_schema` `response_format` (the constrained-decoding
   case); `json_object` is left alone (it is not constrained decoding), deferred to the stricter
   per-engine rules that need it.
2. **Cerebras and Groq migrate onto the seam as per-engine overrides, croak messages unchanged.**
   `Engine::Cerebras` (`Cerebras.pm:68` → `_exclude_tools_with_any_response_format` `:74`) uses a
   `qr//` all-models matcher and refuses `tools` + a `response_format` of **either** type
   (`json_object` or `json_schema`) — stricter than the inherited gpt-oss rule, so it **replaces**
   rather than extends the inherited set. `Engine::Groq` (`Groq.pm:76` →
   `_exclude_json_schema_with_tools_or_streaming` `:82`) is mode-aware: `json_schema` + `has_tools` →
   croak, `json_schema` + `streaming` → croak, while `json_object` + tools passes through; its `qr//`
   all-models rule subsumes the inherited gpt-oss rule for Groq's own gpt-oss route.

## Rationale

- **A boolean flag still cannot spell a pair** (ADR 0021, reaffirmed): a flag asserts *the wire
  accepts field X*; this is a mutual exclusion *between two fields in one call*. The move is about
  *scope*, not about resurrecting the flag idea.
- **A coderef, not a DSL** (ADR 0021's third rejected option, re-weighed and re-declined): the real
  shapes — Groq's mode-specificity plus a non-capability streaming axis, Cerebras's any-type refusal —
  need a mini constraint language to express declaratively. A coderef keyed on the model is honest and
  cheap; it is the pairwise-exclusion sibling of ADR 0019's boolean `{ cap => 0|1 }` corrections
  (same matcher grammar, coderef payload instead of a hash).
- **Home the shared rule on the dialect base, not the engines**, precisely because the constraint is
  model-intrinsic: declaring it on `OpenAIBase` is what makes a constrained model reached through a
  passthrough aggregator get caught without touching each aggregator engine.

## Consequences

- **The gpt-oss 400 is now caught wherever gpt-oss is served**, including the TSystems / AKIOpenAI
  defaults and the OpenRouter / HuggingFace / Replicate aggregator routes — the transitivity ADR 0021
  had to leave uncovered under engine scope.
- **ADR 0002 / ADR 0019 are unchanged**: this seam sits *above* the boolean registry, at the
  `chat_f` / `chat_stream_realtime_f` layer, exactly where ADR 0021 put it; only its keying moved from
  engine to model.
- **ADR 0005 is unaffected**: the guard still reads the post-rewrite body, so an ADR 0005 single-path
  rewrite pre-empts it.
- **Verified offline** (no live calls): `t/78_model_capability_exclusions.t` covers the model-scoped
  discrimination (a sibling model on the same engine is untouched), the aggregator transitivity
  (gpt-oss reached through a passthrough engine still croaks), the Groq `json_object` + tools
  pass-through, and the Cerebras any-type refusal.

## Future work

- **One live-unverified inference, flagged for reconciliation** (needs a karr ticket — this ADR
  round does not touch the board): the shared gpt-oss rule is deliberately **`json_schema`-only**,
  because Groq confirms `json_object` + tools *works* on gpt-oss. Whether the **TSystems / AKIOpenAI**
  gpt-oss backends *also* 400 on `json_object` + tools is unverified. The `json_schema`-only rule is a
  **common-denominator** reading — it never over-fires (it lets `json_object` through everywhere), at
  the cost of possibly under-firing on a backend that happens to reject `json_object` + tools too.
  Resolve by live-probing a TSystems / AKIOpenAI gpt-oss route, then either widen the OpenAIBase rule
  or add a per-engine override.

## Cross-links

- **Supersedes the mechanism of ADR 0021** — the per-engine hook is gone; its *Context / Decision /
  Rationale* about **why** a pairwise exclusion is a runtime guard (not a flag, not a lossy
  auto-rewrite, and a fail-loud croak is the minimum) stand unchanged.
- **Extends ADR 0019** — the model-scoped `chat_model`-keyed table, from boolean corrections to
  pairwise exclusions; same matcher grammar, coderef payload.
- **A per-request `model` override does not re-scope the rules** — they match `chat_model`; a
  `chat_f` / stream override whose matched rule set differs is warned (ADR 0019 Update k352).
- **Sits above ADR 0002** — the boolean capability registry, untouched.
- **Nuances ADR 0005** — its single-path rewrites are unaffected and pre-empt the guard.
- `CONTEXT.md` gains a `model_capability_exclusions` entry, sibling to `model_capability_corrections`,
  in the capability-axis vocabulary.

## Update (k184 — live-verify: Groq rejects `json_object` + tools too; the "model-intrinsic" premise is a serving-stack property)

A Getty-approved live probe (2026-09-19, raw `/chat/completions`, `gpt-oss-120b` tools ×
`response_format` matrix — karr #184) corrected two claims this ADR made: one resolved, one parked.

- **RESOLVED — the Groq `json_object` + tools pass-through is disproven.** §Decision.2 ("`json_object`
  + tools passes through"), the §Consequences "Groq `json_object` + tools pass-through" bullet, and the
  §Future-work "common-denominator" reasoning all rested on *"Groq confirms `json_object` + tools works
  on gpt-oss."* **It does not.** Groq 400s `json_object` + tools with the *same* "json mode cannot be
  combined with tool/function calling" message it returns for `json_schema` + tools.
  `Engine::Groq::_exclude_json_schema_with_tools_or_streaming` now croaks **both** `json_object` and
  `json_schema` in the tools branch (the streaming branch stays `json_schema`-only — `json_object` +
  streaming is not live-disproven), so Groq is now any-`response_format`-refusing in the tools lane,
  like Cerebras. The stale "`json_object` is allowed alongside tools" comments on `Groq.pm` and
  `OpenAIBase.pm` are corrected. This does **not** touch the shared `OpenAIBase` `gpt-oss` rule, which
  stays `json_schema`-only.

- **PARKED — the "model-intrinsic" premise is only half true.** §Context and §Rationale argue the
  `tools` + `json_schema` conflict is *"a property of the MODEL, not the endpoint … it fires wherever
  gpt-oss is served,"* which is why the shared rule is homed on `OpenAIBase`. The same probe refutes
  the universal reading: **AKI (`aki.io/openai/v1`) serves `gpt-oss-120b` + tools + `json_schema` with
  HTTP 200** (a real `tool_call` returned). So the conflict is a **serving-stack** property — Groq and
  Cerebras enforce it platform-wide, AKI's SGLang backend does not — and the shared `qr/gpt-oss/` rule
  is a confirmed **false-positive on `AKIOpenAI`**. (Orthogonally, AKI rejects `json_object` at all on
  that backend — a missing-capability 400, not a tool-grammar conflict.)

  **The shared `OpenAIBase` `gpt-oss` rule was deliberately left unchanged.** Getty's decision
  (2026-09-19): ship only the live-verified Groq subset now; keep the shared rule and its placement
  pending confirmation from the *other* gpt-oss default, **TSystems**. **That confirmation cannot come
  from a live probe: the project has no available developer key for T-Systems AIFS** (the key was
  empty at probe time and none is obtainable; Cerebras separately returned 402). TSystems is therefore
  permanently not live-testable, and its wire behavior must be read from documentation
  (`docs.llmhub.t-systems.net`), not observed. So this ADR's **Decision stands as shipped**; the
  model-vs-stack scope question and the AKI false-positive remain open in **karr #184**, to be resolved
  on a **documentation basis** — either narrowing the shared rule off the pure-model axis (per-engine /
  per-stack scope) or accepting the false-positive as the safe common denominator.

- **The mechanism is untouched.** The per-model exclusion table, the coderef payload, and the
  base-vs-engine homing (§Decision) are exactly as shipped; this Update corrects a wire *fact* and
  reopens a scoping *premise*, not the seam. It **supersedes the original §Future-work item** ("one
  live-unverified inference"): that probe has now run — the Groq half is resolved, the gpt-oss half is
  karr #184. Verified offline: `t/78_model_capability_exclusions.t` and `t/78_capability_exclusions.t`
  now assert Groq `json_object` + tools croaks (and `json_object` without tools still passes).

## Update (k184 Option C — the shared `gpt-oss` rule is removed from `OpenAIBase`; the parked scope question is RESOLVED)

The previous Update left one item **PARKED**: whether the shared `qr/gpt-oss/` rule stays homed on
`Engine::OpenAIBase` or moves off the pure-model axis, pending a TSystems confirmation that could only
come from documentation (no developer key). Getty resolved it on **2026-09-19 (Option C, karr #184;
code in commit `de5efa3`)**: **remove the shared rule.** That PARKED item — and the "keep the shared
rule and its placement pending TSystems" guidance inside it — is therefore now **RESOLVED**; the state
below is live, so no earlier "keep it / doc-based reconciliation" reading stands.

- **§Decision.1 is reversed.** `Engine::OpenAIBase` no longer overrides `model_capability_exclusions`;
  the override and its `_exclude_tools_with_json_schema` helper are deleted, and the base inherits the
  `Langertha::Role::Chat` no-op. No OpenAI-dialect engine inherits a `gpt-oss` exclusion any more.

- **The "model-intrinsic" premise (§Context, §Rationale's third bullet) is retired.** The AKI-200
  evidence the previous Update recorded is now the ruling fact, not a parked one: AKI
  (`aki.io/openai/v1`, SGLang backend) serves `gpt-oss-120b` + `tools` + a `json_schema`
  `response_format` at **HTTP 200**. The conflict is a property of the **serving stack**, not of the
  gpt-oss model — Groq and Cerebras enforce it platform-wide (each via its own all-models override),
  AKI does not.

- **§Consequences is corrected.** The headline *"the gpt-oss 400 is now caught wherever gpt-oss is
  served"* no longer holds and is **withdrawn**. The aggregator/default transitivity (TSystems /
  AKIOpenAI `gpt-oss` defaults; OpenRouter / HuggingFace / Replicate `.../gpt-oss-` routes) is
  **deliberately no longer caught** — those routes now send `tools` + `json_schema` together on the
  wire. A stack that *does* enforce the conflict on such a route (a possible but not live-testable
  TSystems / aggregator gpt-oss backend) now returns an **opaque provider 400** instead of a local
  croak. This is an **accepted trade-off** (Getty, Option C), **reversible** by adding a per-engine
  (per-stack) override once a live-confirmed or documented enforcing stack is found.
  `t/78_model_capability_exclusions.t` now asserts the no-croak / both-fields-on-the-wire behavior for
  those routes.

- **The seam and the Groq/Cerebras rules are untouched.**
  `Langertha::Role::Chat::model_capability_exclusions`, its ordered `( $matcher => $rule )` coderef
  contract, and the two engine overrides (`Engine::Groq`, `Engine::Cerebras`, both all-models `qr//`
  rules) stand exactly as shipped. This Update reverses the shared-rule **homing** only — §Decision's
  seam mechanism, and ADR 0021's reaffirmed premise, are unchanged.

karr #184 is closed by this decision.

## Update (k223 — an empty `chat_model` is matched as `''`, as the corrections table does)

`_check_capability_exclusions` used to return early when `chat_model` was undef or empty. Since
ADR 0019's k209 Update, `_apply_model_capability_corrections` matches that case as `''` instead,
so the two model-scoped tables disagreed: `Groq` / `Cerebras` with `model => ''` skipped their
all-models `qr//` rule and sent `tools` + `response_format` to a provider that 400s it. The
walker now reads `chat_model // ''` like the corrections table and still returns early only for
a consumer without a `chat_model` method. Only a matcher that accepts the empty string fires on
`''` (the engine-wide `qr//` rules do; a family regex or an exact id does not), so no
model-specific rule starts firing for a missing model. The seam's contract is otherwise
unchanged. `t/78_model_capability_exclusions.t` asserts the croak for `model => ''` on both
engines.

## Update (k245 — rules also receive `tool_choice_forced`; SGLang refuses a forced tool with a `response_format`)

SGLang's OpenAI server (`python/sglang/srt/entrypoints/openai/protocol.py`, since 307a90f6d3 /
17ba2c2e7c, source-checked 2026-09-25, no live call) raises *"tool_choice 'required' or a named tool
cannot be combined with response_format, regex, or ebnf"* when the tools carry a tool-call
constraint, the request carries an output constraint (`json_schema`; `json_object`, which SGLang
turns into `json_schema '{"type":"object"}'`; `structural_tag` — not `text`) and `tool_choice` is
`required` or a named tool. `tool_choice auto` with a `response_format` is accepted. SGLang claims
`tool_choice_any` / `tool_choice_named` and `response_format_json_schema`, so no ADR 0005 rewrite
applies and the caller got an opaque 400.

The rule needs to know whether the choice is **forced**, which `has_tools` cannot say (it is true
for tools + `auto` too, which SGLang accepts). So the seam's request context gains one key:

- **`tool_choice_forced`** — true when the caller's `tool_choice` reads (via
  `ToolChoice->from_hash`) as `any` or a named tool. It is computed next to `has_tools` at both
  call sites (`chat_f`, `chat_stream_realtime_f`), from the request **as the caller passed it**:
  the `tool_choice` gate (`_gate_tool_choice`) runs later, inside `chat_request`, so a rule sees
  what was asked. After the ADR 0005 forced-tool rewrite, which deletes `tool_choice`, it is 0.
- The existing keys (`has_tools`, `response_format`, `streaming`) and the Groq / Cerebras rules
  are unchanged; a rule that ignores the new key behaves as before.

`Engine::SGLang` declares an all-models `qr//` rule
(`_exclude_forced_tool_choice_with_response_format`): `has_tools` + `tool_choice_forced` + a
`response_format` of type `json_schema` / `json_object` / `structural_tag` croaks, naming the
SGLang server restriction. It stays a croak, not a rewrite (ADR 0021's premise). The server
exempts tool parsers whose constraint is `full_assistant_ebnf`; that is a launch-time choice
Langertha cannot see, so the rule holds for every model — a possible over-croak on such a server,
accepted for the same reason Groq and Cerebras use all-models rules. Verified offline:
`t/23_sglang_forced_tool_exclusion.t`.

The guard reads the `response_format` passed to the call, not one set as an engine attribute
(`$engine->response_format`), which the request builder still sends. That gap predates this
Update and applies to every rule; it is filed separately as karr k249.

## Update (k249 — rules receive the effective `response_format`, engine attribute included)

The gap named at the end of the k245 Update is closed. `chat_f` and `chat_stream_realtime_f`
now pass the rules the `response_format` that goes on the wire, resolved by
`Role::Chat::_chat_effective_response_format`: the per-request value when the caller passed the
key, else the engine's `response_format` attribute (`Role::ResponseFormat`). That is the
precedence every request builder already uses (`OpenAICompatible` `chat_request` /
`chat_stream_request`, `AnthropicCompatible::_take_response_format`, `ResponsesCompatible`), so
the guard and the wire cannot disagree: an engine-level `json_object` on Groq plus tools now
croaks, and a per-request `{type => 'text'}` lifts an engine-level JSON format in both places.
The rule signature and the Groq / Cerebras / SGLang rules are unchanged. Verified offline:
`t/78_capability_exclusions.t`, `t/23_sglang_forced_tool_exclusion.t`.

The ADR 0005 forced-tool rewrite in `chat_f` does not share the bug: it sets a per-request
`response_format`, which then wins over the engine attribute on the wire and in the guard alike.
It does overwrite a `response_format` the caller also passed (per request or on the engine)
without a word — a separate question, not changed here.

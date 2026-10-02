# ADR 0021 — Pairwise capability exclusions are a per-engine `chat_f` guard, not a capability flag

- Status: accepted
- Date: 2026-09-14
- Tags: capabilities, tools, structured-output, chat_f, streaming, model-scoped
- Superseded-in-part-by: **ADR 0024** — the *mechanism* moved from a per-engine hook to the
  model-scoped `model_capability_exclusions` table (k148). The premise below (a runtime guard, not a
  boolean flag, not an auto-rewrite) is reaffirmed there, not overturned; only the placement changed.
  See the closing Update.

## Context

ADR 0002 models each capability as an independent boolean — *the wire accepts this
field* — and ADR 0019 refined that resolution from per-engine to per-model. Neither can
express a **relationship between two** capabilities: that combining `tools` **and** a
structured-output `response_format` **in one request body** is rejected, even though each
field is individually supported and individually advertised. A boolean is a property of one
flag; this is a constraint across a pair, evaluated per call.

Two OpenAI-dialect providers impose exactly such a constraint (advisor re-verified against
live docs 2026-09-14, karr #142):

- **Cerebras** rejects a body carrying both `tools` and a `response_format` — of *either*
  type, `json_object` or `json_schema` — with an opaque **HTTP 400 and no body**. Its docs
  now frame this as per-model, but every model this engine serves (`gpt-oss-120b` default,
  `zai-glm-4.7`) rejects the combination, and none is documented as allowing it.
- **Groq** makes it **mode-aware and three-way**: *Structured Outputs* (`response_format`
  type `json_schema`) are mutually exclusive with tool use **and** with streaming, each a
  400. `json_object` mode is a separate feature that **is** allowed alongside tools, so a
  naive "tools + response_format" refusal would over-fire on Groq `json_object`.

This dents — but does not overturn — the ADR 0005 premise that structured output and forced
tool calling are two faces of one freely inter-convertible mechanism. ADR 0005's own two
rewrites always emit a **single-path** body (tools → `response_format`, or `response_format`
→ synthetic tool); they never produce both at once. The failure here is the orthogonal case
ADR 0005 never addressed: a caller passing **both** forms in one `chat_f` call. Without a
guard, `chat_f` assembles a body the provider 400s, and the caller sees an opaque transport
error (`… request failed: 400`, no body) instead of a diagnosis.

## Decision

Express the exclusion as a **per-engine hook consulted at the `chat_f` layer**, above the
boolean registry — exactly where a cross-flag, per-call constraint belongs.

1. **`Langertha::Role::Chat::_check_capability_exclusions`** (`lib/Langertha/Role/Chat.pm:444`)
   is a **deliberate no-op on the base**. `chat_f` consults it after building the effective
   request (`Chat.pm:500`, `streaming => 0`) and `chat_stream_realtime_f` consults the same
   hook (`Chat.pm:654`, `streaming => 1`). It is handed `has_tools`, `response_format`, and
   `streaming`.

2. **`_chat_tools_requested`** (`Chat.pm:448`) computes the tool signal: true when `%opts`
   carries a `tools` array **or** a forced named `tool_choice` (parsed via
   `Langertha::ToolChoice->from_hash`, `type eq 'tool'`).

3. **Only the two affected engines override the hook and `croak`**, naming the engine, the two
   conflicting fields, and that the provider rejects the combination with a 400 — and pointing
   at the legal alternatives (send one, not both; run the tools first, then a second
   structured-output turn):
   - **`Engine::Cerebras`** (`lib/Langertha/Engine/Cerebras.pm:65`): `has_tools` + a
     `response_format` of either `json_object` or `json_schema` → croak. Engine-wide, because
     every currently-served model rejects it (both `chat_f` and the streaming path).
   - **`Engine::Groq`** (`lib/Langertha/Engine/Groq.pm:73`): **mode-aware** — fires only for
     `json_schema`. `json_schema` + `has_tools` → croak; `json_schema` + `streaming` → croak
     (regardless of tools). `json_object` + tools passes through untouched, on both paths.

4. **The guard evaluates the effective, post-rewrite request.** It is consulted *after* the
   ADR 0005 forced-named-tool fallback (`Chat.pm:462-494`), which may delete `tools` and set a
   `response_format`. So if ADR 0005 already collapsed the request to a single-path body, the
   guard correctly does **not** fire; the two mechanisms compose without double-counting.

5. **Scope is exactly Cerebras + Groq**, established by walking the whole OpenAI-family Tools
   fleet (karr #142): the precondition for `chat_f` to build a conflicting body is that the
   engine advertises **both** `tools_native` and `response_format_json_schema`. OpenAI supports
   the combination (not affected); the other candidate pairs (DeepSeek, MiniMax, Hetzner) were
   already neutralised at the boolean layer by k138 / ADR 0019, so `chat_f` cannot form the
   pair there. The base no-op is asserted by the scope check in `t/78_capability_exclusions.t`
   (OpenAI, advertising both flags, must not croak).

## Rationale

Three shapes were on the table (karr #142, advisor note 2026-09-14). The other two were
rejected on their merits, not skipped for time:

- **A boolean flag / a `model_capability_corrections` entry — structurally impossible.** A flag
  asserts *the wire accepts field X*; a mutual exclusion is a constraint *between two* flags in
  one call and has no boolean spelling. ADR 0019 foresaw exactly this and parked it as Future
  work with an explicit instruction: *do not stretch the boolean table to fake it.*

- **Auto-rewrite in the ADR 0005 direction — rejected as lossy.** ADR 0005's rewrites fire on a
  capability **gap**: the caller sent one form the engine cannot do, so swap to the lossless
  equivalent. Here the caller sent **two** forms and the engine can do **neither together** —
  there is no lossless single path. Dropping `tools` discards the tools; dropping
  `response_format` discards the structured final answer. Either way the framework would
  **silently discard half the caller's intent** — precisely the "wrong answer, not an error"
  failure ADR 0019 warns against. The correct resolution (run the tools, then a second
  structured-output turn — Cerebras's own recommendation) is a two-turn flow that single-turn
  `chat_f` structurally cannot perform.

- **A declarative `capability_exclusions` DSL — rejected as both over- and under-powered.**
  Over-built for two providers (House Rule 2). And a flat list of exclusive flag-pairs cannot
  express the actual shapes without becoming a mini constraint language: Groq needs
  mode-specificity (`json_schema` not `json_object`), a non-capability axis (streaming), and
  per-model scope; Cerebras needs any-`response_format` + per-model. That is a genuine
  architecture decision — the maintainer's call, not a worker's.

The croak is the right minimum because it converts a known opaque provider 400 into a clear
**local** error that names both conflicting fields: non-lossy, reversible, fail-loud (house
rule), correct for 100% of today's Cerebras/Groq models, and it touches **no ADR-governed
seam** — the boolean registry (ADR 0002/0019) is untouched and ADR 0005's single-path rewrites
still stand.

## Consequences

- **The constraint lives above the boolean registry.** ADR 0002 and ADR 0019 are unchanged;
  the guard is a new, orthogonal layer at the `chat_f`/`chat_stream_realtime_f` level, the one
  place with the whole effective request in view.
- **It composes cleanly with ADR 0005.** The guard fires only on the both-at-once case ADR 0005
  never covered, and because it reads the post-rewrite body, an ADR 0005 rewrite that already
  resolved the request pre-empts it.
- **Engine-scoped, therefore honest-but-imprecise for the future.** A Cerebras model that later
  lifts the limit per-model would draw a false croak, and `gpt-oss-120b` reached *through* an
  aggregator (TSystems and AKIOpenAI both default to it) is under-covered. Neither is a live bug
  today — every currently-served Cerebras/Groq model rejects the combination — so both are
  recorded as known limits, not defects.
- **Verified offline.** `t/78_capability_exclusions.t` (mocked, no live calls) covers both
  engines, the Groq `json_object` + tools pass-through (the over-fire the advisor warned of),
  the forced-`tool_choice` tool signal, the streaming path, and the OpenAI base-no-op scope
  check; each of the five guards is sabotage-verified (removing one turns matching assertions
  red).

## Future work

All three deferred to the maintainer — each embeds the engine-vs-model precedent ADR 0019
parked. karr #142 stays in review for these decisions; nothing below blocks the shipped guard.

- **Model-scoped generalization.** Make the constraint travel with the **model**
  (`gpt-oss-120b` + a few constrained-decoding stacks) rather than the engine, so it also
  catches the model reached via TSystems / AKIOpenAI and self-corrects if Cerebras lifts the
  limit per-model. Needs a **new per-model seam** beside `model_capability_corrections` — the
  k142 architecture question ADR 0019 explicitly reserved for the maintainer.
- **Aggregator transitivity.** OpenRouter / HuggingFace / Replicate / TSystems / AKIOpenAI pass
  through to a backend and can hit the same 400 when routed to `gpt-oss-120b` or a Groq-style
  stack. That is a per-route / per-model property, not an engine one, so it is intentionally not
  encoded here.
- **A declarative `capability_exclusions` layer / constraint language.** Reconsider only if a
  third or fourth provider needs it and the shapes converge; today it is over-built for two.

See ADR 0002 (the boolean registry this sits above), ADR 0019 (the model-scoped boundary that
reserved this exact problem as Future work), and ADR 0005 (the unify-and-rewrite premise this
nuances — its single-path rewrites are unaffected). `CONTEXT.md` carries the capability-axis and
`model_capability_corrections` vocabulary this decision deliberately does **not** extend.

## Update (k148 — the mechanism is now model-scoped; see ADR 0024)

The **first Future-work item above — "Model-scoped generalization" — is now realized** (k148). The
per-engine `_check_capability_exclusions` override this ADR shipped is **superseded** by an ordered,
`chat_model`-keyed `model_capability_exclusions` table on `Role::Chat`, mirroring ADR 0019's
`model_capability_corrections` with a coderef rule payload. The shared `gpt-oss` rule now lives on
`Engine::OpenAIBase`, so the constraint travels with the model to the TSystems / AKIOpenAI defaults
and the OpenRouter / HuggingFace / Replicate aggregator routes (the second and third Future-work
items) — not just the direct Cerebras route; Cerebras and Groq keep their exact croak messages as
per-engine overrides on the new seam. The DSL (third Future-work item) was **weighed again and
declined** — the rule payload stays a coderef. Everything in this ADR's *Context / Decision /
Rationale* about **why** the guard is a runtime check above the boolean registry (no boolean spelling
for a pair; auto-rewrite is lossy; the croak is the fail-loud minimum) stands unchanged; only the
scope and home of the check moved. Full record: **ADR 0024**.

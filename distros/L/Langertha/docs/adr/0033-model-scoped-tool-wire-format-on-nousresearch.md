# ADR 0033 — `tool_wire_format` is model-scoped on `Engine::NousResearch`

- Status: accepted
- Date: 2026-09-29
- Tags: tools, wire-format, capabilities, model-scoped, hermes
- Cross-links: ADR 0001, ADR 0002, ADR 0019, CONTEXT.md
- karr: #238

## Context

ADR 0001 fixed `tool_wire_format` as **one enum per engine**: an engine declares the single
tool dialect it speaks, and `_build_tool_wire_format` resolves it once — its default following
the engine's base-class hierarchy. `Engine::NousResearch` composed `Role::HermesTools` and
pinned the tag to `hermes` for the whole engine, on the premise that Nous serves Hermes models
and Hermes models want the prompt-injection wire.

That premise is only true for a slice of the endpoint. The Nous inference API
(`inference-api.nousresearch.com/v1`) is an **OpenAI-compatible gateway fronting ~341 models** —
`Hermes-*` and `DeepHermes-*` alongside `anthropic/…`, `openai/…`, `google/…` slugs that route
to their real backends. Those non-Hermes backends take **native OpenAI `tools`**; pinning the
engine to `hermes` rendered every one of them wrong — the tools rode a system prompt the real
backend never interpreted as a tool contract, and `chat_f` rewrote a forced tool into a
`json_schema` fallback that native tool-callers never needed.

The k251 Update to ADR 0002 had already made the capability side model-aware in spirit: the
`Role::HermesTools` layer-2 rule was changed to key on the **resolved** `$self->tool_wire_format`
(so a `tool_wire_format => 'openai'` constructor override kept the native flags and dropped
`tools_hermes`), and it explicitly parked "a model-aware tag builder (k238 step c)" as out of
scope. This ADR is that step: the tag itself becomes model-aware, and the k251 flag machinery
follows it for free.

## Decision

**`Engine::NousResearch` resolves `tool_wire_format` per instance from `chat_model`. Every other
engine keeps the ADR 0001 engine-scoped tag.**

1. **One shared predicate names the exception.** `_is_hermes_model` matches `chat_model` against
   `\A(?:nousresearch/)?(?:nous-)?(?:deep)?hermes` (case-insensitive) — Hermes-4/-4.3, Hermes-3,
   DeepHermes, the `nousresearch/` prefix, and the legacy `Nous-Hermes-2` form.
2. **The tag builder reads it.** `_build_tool_wire_format` returns `hermes` for a Hermes model
   (the named exception) and `openai` for every other slug and every unknown new one (the
   default). `default_model` is `Hermes-4-70B`, so reading `chat_model` in the builder never
   croaks.
3. **The tag is still resolved once per instance and never re-derived per request.** A
   `tool_wire_format => …` constructor argument wins over the builder in both directions via the
   Role::Tools init_arg (the `_tool_wire_format_given` trigger of the k251 Update), so a user can
   force either wire on any slug. A per-request `chat_f(model => …)` rewrites only the outbound
   body `model` field (`OpenAICompatible` `chat_request` applies `%extra` last); it touches
   neither `chat_model` nor the resolved tag.
4. **Capability flags follow the resolved tag, not the tag builder.** The already-landed k251
   layer-2 rule in `Role::HermesTools` keys on `$self->tool_wire_format`: on `hermes` it clears
   `tools_native` / `tool_choice_any` / `tool_choice_named` / `parallel_tool_use` and keeps
   `tools_hermes`; on any other tag it clears `tools_hermes` and keeps the native flags from the
   role inventory. Nothing new is needed — the flags already discriminate per resolved tag, so a
   Hermes model on one instance and a Claude slug on another advertise divergent tool flags from
   the one engine class.
5. **The reasoning system-prompt is gated on the model, not the tag.** The `reasoning => 1` Nous
   chain-of-thought prompt (prepended in `around _system_messages`) is gated on the **same
   `_is_hermes_model` predicate**, not on `tool_wire_format eq 'hermes'`. On a non-Hermes slug it
   is dropped with one carp; on a genuine Hermes model it is kept even when the caller has forced
   `tool_wire_format => 'openai'`.

## Rationale

**Why native is the default and Hermes the named exception.** `hermes` is a client-side tool
*transport* (definitions injected into the prompt, `<tool_call>` text lifted onto
`Response.tool_calls`), not an endpoint dialect — the OpenAI-chat envelope is unchanged, so
ADR 0006 is intact. The overwhelming majority of slugs on this gateway (the 280+ non-Hermes
backends, and any unknown new one) route to real backends that accept native OpenAI tools, so
native is the correct default and the safe fallback for an unrecognized id.

**Why `hermes` remains the robust choice for Hermes models — and why this retires the
maintainer-approved live probe.** The probe would have asked "does Nous accept native tools for
Hermes-4?" It does — but per upstream `NousResearch/hermes-agent#741`, Hermes-4 *intermittently*
emits its tool calls as `<tool_call>` XML / bare JSON text with `finish_reason=stop` and empty
native `tool_calls`, even with native calling wired up. Langertha's `hermes` wire is exactly the
lane that lifts that text onto `Response.tool_calls`. Forcing native for Hermes would reintroduce
that upstream bug; the conservative hermes-for-Hermes default is correct in **both** probe
outcomes, which is why the design proceeded offline without spending the probe.

**Why decouple the reasoning prompt from the tool transport.** Gating the Nous reasoning prompt
on `_is_hermes_model` rather than the tag means a user who forces `tool_wire_format => 'openai'`
on a genuine Hermes model — a legitimate choice if they trust that model's native calling —
does not silently lose the Hermes reasoning system-prompt. The two concerns (which tool wire,
whether the reasoning prompt applies) are properties of the model, resolved from the same
predicate but never coupled to each other.

**Why option D and not the alternatives.**

- **Rejected — B, a generic declarative framework table keyed on `chat_model` (a "tag
  corrections" sibling of `model_capability_corrections`).** Only one consumer needs it, so it
  violates the ADR 0016 placement rule; it would drive **dispatch** rather than flags, which the
  ADR 0019 layer model deliberately does not cover (that table asserts/clears boolean caps, it
  does not select a serializer); and it gains nothing over the one `_build_tool_wire_format`
  override on the one engine that has this shape.
- **Rejected — C, a separate `NousPortal` class pinned to the `openai` tool wire.** Sound in
  isolation, but it forces the user to pick the class by model, and it still lets the Hermes
  class silently `hermes`-wrap a Claude slug — the exact bug this ADR closes.
- **Chosen — D, a per-instance model-aware tag on `NousResearch` only, with the tool-transport
  flags following the resolved tag.** One builder override on the one engine whose endpoint is a
  multi-backend gateway; no new framework, no class proliferation, and the k251 flag machinery
  already tracks the resolved tag.

## Consequences

- **`tool_wire_format` is no longer strictly engine-scoped (nuances ADR 0001).** On
  `NousResearch` it is resolved per instance from `chat_model`. It is still one resolved tag per
  instance, resolved once and never re-derived per request; the ADR 0001 invariant "an engine
  carries no per-format tool code" is untouched — the tag still keys the value-object dispatch,
  only its *value* now varies with the model on this one engine.
- **`tools_native` vs `tools_hermes` can differ per model on one engine instance (nuances
  ADR 0002).** The manifest publishes divergent tool flags for the same engine class across its
  probed models — a Hermes model reports `tools_hermes`, a Claude slug reports `tools_native` —
  because the k251 rule keys on the resolved tag.
- **This is a layer-3-like model-scoped correction that corrects the WIRE TAG, not a capability
  flag (relates to ADR 0019).** ADR 0019's `model_capability_corrections` refines boolean caps
  per `chat_model` inside `engine_capabilities`; here the per-model resolution happens one step
  earlier, on the tag builder, and the caps then follow via the layer-2 rule. Same axis
  (per-model wire reality), different target (the dispatch tag, upstream of the flags).
- **The manifest per-model clone hazard is closed.** `Manifest::Builder::_capability_clone`
  probes each model on a `clone_object` copy, which copies an already-built lazy tag; it calls
  `_reset_derived_tool_wire_format` (drops a builder-made tag via `_clear_tool_wire_format`,
  keeping a constructor-given one through `_tool_wire_format_given`, per the k251 Update) so a
  per-model probe re-resolves the tag for its own `chat_model` instead of inheriting a stale one.
- **Verified offline** (no live calls): the model-aware tag resolution and the divergent flags
  are covered alongside the k251 override tests (`t/66_hermes_tag_override.t`,
  `t/66_nousresearch_model_wire.t`, `t/96_manifest_builder.t`).

## Future work

- **karr #352** — the step-(a) carp when a `chat_f` / `chat_stream_realtime_f` `model` argument
  differs from `chat_model` (so the caller learns the tag / capabilities were resolved for a
  different model than the request body names). This is a pre-existing hole spanning layer 3 /
  ADR 0023 / ADR 0024, broader than #238; split out rather than solved here. Resolved by k352 as a
  warning, not a re-scope: an override that flips the resolved tag (or the reasoning prompt) carps
  (ADR 0019 Update k352).
- **Step (f) — `Role::StaticModels` → a live `/v1/models` listing** for NousResearch, so the
  ~341-model gateway is discoverable rather than pinned to three static Hermes ids. A separate
  ticket, gated on knarr k20.

`CONTEXT.md` carries the `tool_wire_format` vocabulary (the single per-engine enum, the
value-object dispatch, `hermes` as one tag value like any other) and the
`model_capability_corrections` / `model_capability_exclusions` entries this ADR sits beside; it
is not restated here. See ADR 0001 (the engine-scoped tag this nuances), ADR 0002 (the k251
tag-keyed capability rule the flags follow), and ADR 0019 (the model-scoped correction layer this
parallels one step upstream).

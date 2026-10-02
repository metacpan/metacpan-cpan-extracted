# ADR 0015 — `-excludes` and per-family `engine_capabilities` correction are canonical patterns

- Status: accepted
- Date: 2026-08-15
- Tags: roles, capabilities, composition, wire-format, anthropic, openai, generation-parameters

## Context

The doku audit on 2026-08-14 surfaced two complementary drifts in the engine /
role composition lane. They are independent observations, but both live in the
same seam (Perl role composition + how dialect bases override collision-prone
defaults), and they share the same fix: capture each pattern as the canonical
shape, written down once, so the next reader doesn't have to rediscover it from
scattered code comments.

### Finding 1 — `-excludes` is a non-obvious role-composition workaround

When `Langertha::Engine::AnthropicBase` composes its roles, it uses the plain
`with` list with per-role `-excludes` clauses (`AnthropicBase.pm:9-19`), not
the simpler `with 'Langertha::Role::X'`. The reason isn't taste — it's
**collision resolution**. Each role ships a default wire-format builder that
disagrees with the dialect's own wire family (`_build_tool_wire_format` →
`'openai'` in `Role::Tools.pm:115`, `_build_cache_wire_format` → `'openai'`
in `Role::PromptCache.pm:59`, `_build_reasoning_wire_format` → `'openai'` in
`Role::ReasoningEffort.pm:57`, `content_format` → `'openai'` in
`Role::Chat.pm:31`); without `-excludes`, the composer would either resolve
the conflict non-deterministically or fail to load the class — the exclusion
tells Moose to skip the role's builder so the dialect role composed
alongside (`Role::AnthropicCompatible`) can supply the override.

The companion shape — the `with map { 'Langertha::Role::'.$_ } qw(...)` list
— is the canonical form for dialect bases whose role inventory *agrees*
with the role defaults and so needs no exclusions. The live exemplar is
`Engine::OpenAIBase.pm:10-22`: the OpenAI family inherits the role builders
verbatim, and the `map` form simply makes the *intentional* OpenAI-family
role set visible. A new reviewer reading either idiom sees an unusual Perl
shape and has no quick pointer to "this is how we resolve dialect-base role
composition".

### Finding 2 — Per-family `engine_capabilities` correction is symmetric but undocumented side-by-side

Both dialect bases correct the wire reality in an `around engine_capabilities`
clause, but they correct *different* flags, for *opposite* reasons:

- `Langertha::Engine::OpenAIBase.pm:31-36` — the OpenAI family caches
  automatically (there is no request-side breakpoint), so it deletes
  `prompt_cache_key` and keeps only the `prompt_cache` enable flag. Comment:
  *"Clear the Anthropic-style enable flag here so the whole family advertises
  only the key (ADR 0002)."*
- `Langertha::Engine::AnthropicBase.pm:32-37` — the Anthropic family has the
  `cache_control` enable breakpoint but no OpenAI-style routing key, so it
  deletes `prompt_cache_key` and keeps only the `prompt_cache` flag. Comment:
  *"Clear the key flag so only the enable flag is advertised (ADR 0002)."*

The two comments read as if one is the inverse of the other, but each is
written in isolation. A reader has to flip between the two files to see the
symmetry. The narrower claim in the comments ("the inapplicable flag for this
family") only makes sense once you have both directions in front of you.

### Finding 3 — the generation-parameter block: `Role::OpenAICompatible` is also the asymmetrizer

The doku audit also flagged that `Role::OpenAICompatible::chat_request` /
`chat_stream_request` assemble the generation parameters (temperature,
response_format, response_size, reasoning / cache kwargs) through a small
boilerplate pattern (`$self->has_temperature ? ( temperature => ... ) : ()`,
`$self->reasoning_kwargs_for`, `$self->prompt_cache_kwargs_for`, ...). The
Anthropic dialect role `Role::AnthropicCompatible` duplicates this exact pattern
inline in `chat_request` / `chat_stream_request` because no shared
generation-parameter helper exists yet.

This is not a bug — it's a deliberate split between *wire-aware* assembly
(Anthropic folds `parallel_tool_use` into `tool_choice`, translates
`response_format` to a synthetic tool, threads `inference_geo`, etc. — all
dialect-specific) and *wire-agnostic* emission (OpenAI's generic block). The
asymmetry is real but invisible — there's no documented decision to point to.
The langertha-rules audit text mistakenly references "579d0c8 / ADR 0013" for
this; in fact those tickets concern *envelope* extraction (separate work), not
the generation-parameter block.

## Decision

### 1. The `-excludes` pattern is the canonical way to resolve dialect-base role composition

Concretely: when a dialect base class needs to compose a *role-inventory-style*
set of roles (the always-on family — models/chat/streaming/etc.) and *some of
those roles' defaults collide* with the dialect's wire family, the canonical
shape is the plain `with` list with per-role `-excludes` clauses. The live
exemplar is `Engine::AnthropicBase.pm:9-19`:

```perl
with 'Langertha::Role::Models',
     'Langertha::Role::Chat' => { -excludes => ['content_format'] },
     'Langertha::Role::Temperature',
     'Langertha::Role::ReasoningEffort' => { -excludes => ['_build_reasoning_wire_format'] },
     'Langertha::Role::PromptCache' => { -excludes => ['_build_cache_wire_format'] },
     'Langertha::Role::ResponseSize',
     'Langertha::Role::SystemPrompt',
     'Langertha::Role::ResponseFormat',
     'Langertha::Role::Streaming',
     'Langertha::Role::Tools' => { -excludes => ['_build_tool_wire_format'] },
     'Langertha::Role::AnthropicCompatible';
```

Each `-excludes` clause names the builder whose role default would shadow the
dialect role's override — `Role::AnthropicCompatible` supplies the
`'anthropic'` wire for `_build_tool_wire_format`,
`_build_cache_wire_format`, `_build_reasoning_wire_format`, and
`content_format`, while the rest of the role (the tool-calling loop, the
cache-control attribute, etc.) still composes in.

The companion form — the `with map { 'Langertha::Role::'.$_ } qw(...)` list
— is the canonical shape for dialect bases whose role inventory *agrees*
with the role defaults and so needs no exclusions. The live exemplar is
`Engine::OpenAIBase.pm:10-22`. The `map` form is canonical not because it's
terse but because it makes the *intentional* list visible — every role listed
is one the dialect base keeps, and the order matters when several roles
contribute to the same wire request.

This is **not** a new decision — it's the pattern in
`OpenAIBase.pm:10-22` and `AnthropicBase.pm:9-19` already. The ADR captures
the pattern so the next contributor doesn't re-derive it.

### 2. Per-family `engine_capabilities` correction is a documented direction-pair

`ADR 0002` established that the engine's `around engine_capabilities` is the
sanctioned escape hatch when the wire reality disagrees with the role
inventory. The cache-control flag is the clearest example of *opposite
correction directions per family*, and that symmetry gets canonical text:

| Family | Cache flag kept | Cache flag deleted | Rationale |
|---|---|---|---|
| OpenAI (and all subclasses of `OpenAIBase`) | `prompt_cache_key` | `prompt_cache` | OpenAI caches automatically; there is no request-side enable breakpoint. The `prompt_cache_key` is the only knob the wire exposes. |
| Anthropic (and all subclasses of `AnthropicBase`) | `prompt_cache` | `prompt_cache_key` | Anthropic's `cache_control` block is an *enable breakpoint* per content block. There is no equivalent routing-key field. |

(k200: within the OpenAI family the self-hosted engines additionally delete `prompt_cache_key` —
see the ADR 0009 Update.)

The direction-pair table is the canonical reference; future per-family
corrections (e.g. when a new dialect base is added) follow the same rule —
**delete the inapplicable flag, keep the applicable one, with a comment
naming which flag the wire doesn't speak**. Both directions live in
`ADR 0002`'s escape-hatch paragraph; this ADR adds the explicitly paired
form so the symmetry is discoverable from one place.

### 3. The generation-parameter block asymmetry is a deliberate dialect split; the shared part is a helper on `Engine::Remote`

The boilerplate generation-parameter emission in `Role::OpenAICompatible` (`has_temperature`,
`reasoning_kwargs_for`, `prompt_cache_kwargs_for`, `stream`, …) is *duplicated* into
`Role::AnthropicCompatible` rather than shared through a common helper,
because **the dialect-aware fields (`response_format` translation to a synthetic
tool, `tool_choice` ↔ `parallel_tool_use` folding, `inference_geo`,
`anthropic-version`) all require the wire envelope in scope**. Recording this
as a *deliberate asymmetry, not oversight* prevents a future reviewer from
misreading the duplicated boilerplate as drift.

The wire-agnostic subset, however, *is* shared. The form this ADR originally
left open — `Langertha::Role::GenerationParams` versus a method on the bases —
**is decided: a plain helper method named `generation_kwargs_for` on
`Langertha::Engine::Remote`** (karr #98). No role is created.

- **Why not a role.** `ADR 0016` decision 1 gives the extraction trigger: a
  shared wire shape earns its own `Role::<X>` at the moment a **second consumer
  needs it while descending from a different parent**. Both consumers here —
  `Role::OpenAICompatible` and `Role::AnthropicCompatible`, composed into
  `Engine::OpenAIBase` / `Engine::AnthropicBase` — descend from
  `Engine::Remote`. There is no second parent, so the trigger does not fire and
  0016's scepticism towards symmetry-driven extraction applies in spirit: the
  common ancestor already *is* the shared home.
- **Why the "role from day one" rule does not override that.** `ADR 0016`
  decision 2 puts capabilities on the role axis immediately, single consumer or
  not — but only capabilities: a *separable feature surface* with its own
  attributes and/or lifecycle methods, advertisable through `does($role)` per
  ADR 0002. `generation_kwargs_for` is an emission utility with no attributes,
  no lifecycle methods and no `%ROLE_TO_CAPS` flag, so the decision-2 test does
  not fire either.
- **Naming guard.** The name is deliberately *not* `knobs_kwargs_for`, which
  `Langertha::Role::RuntimeKnobs` already owns for the self-hosted prefix-cache
  knobs (**ADR 0012** decisions 4/5). `generation_kwargs_for` collides with
  nothing.

Concretely:

- **The helper** lives in `lib/Langertha/Engine/Remote.pm:147-182` (comment
  147-157, body 158-164, POD 166-182):

  ```perl
  sub generation_kwargs_for {
    my ( $self, %controls ) = @_;
    return (
      ( $self->can('reasoning_kwargs_for')    ? $self->reasoning_kwargs_for(%controls)    : () ),
      ( $self->can('prompt_cache_kwargs_for') ? $self->prompt_cache_kwargs_for(%controls) : () ),
    );
  }
  ```

  Both dialect roles call it in `chat_request` and `chat_stream_request`
  (`Role::OpenAICompatible.pm:333` / `:457`,
  `Role::AnthropicCompatible.pm:186` / `:411`).
- **What stays inline** — the cut is narrower than the subset this ADR first
  sketched. `temperature` and `has_response_format` were *not* folded in:
  OpenAI emits `seed` between `temperature` and the reasoning kwargs, so moving
  `temperature` into the helper would shift `seed` and change the byte order of
  the OpenAI body. Everything whose *position* in the body is a dialect
  convention (`temperature`, `response_format`, `seed`, `knobs_kwargs_for`,
  `inference_geo`, the `stream` / `parallel_tool_calls` placement) stays at the
  call site. The shared part is exactly the two `can`-guarded control kwargs.
- **Proof of equivalence** — `t/46_generation_kwargs_for_byte_identity.t`
  asserts the request bodies are byte-identical before and after, the check
  this ADR named as the remaining precondition.

## Rationale

ADR 0002 already authorized the `around engine_capabilities` escape hatch.
ADR 0006 split inheritance (wire dialect) from composition (capabilities).
This ADR layers the *mechanics* on top:

- **Pattern canon** (decision 1) makes the `map`-role-list shape obvious
  rather than a Perl-quirk. Future dialect bases (Gemini, Ollama,
  TranscriptionBase, AKI, LMStudio native) should use the same shape.
- **Direction-pair table** (decision 2) — a single table saying
  "OpenAI keeps X and deletes Y; Anthropic keeps Y and deletes X" is more
  useful than two near-identical code comments in two files because it
  makes the *invariant* (delete the inapplicable flag) explicit and
  generalises to future per-family corrections.
- **Explicit asymmetry** (decision 3) is cheaper than a half-done refactor.
  Naming "the generation-parameter block is duplicated because the
  dialect-aware fields around it need wire context" is the right level for
  now — the wire-agnostic subset is shared through the
  `generation_kwargs_for` helper on `Langertha::Engine::Remote` (karr #98;
  the open design question closed by #111), not a new role, because
  ADR 0016's second-consumer trigger does not fire (both consumers
  descend from `Engine::Remote`).

## Consequences

- **Cross-links.** ADR 0002 (capabilities from role inventory + the
  `around engine_capabilities` escape hatch this ADR extends). ADR 0006
  (the wire-dialect × capability split that makes `#64`-style refactors
  possible — the generation-parameter asymmetry only became safely
  *extractable* once the Anthropic wire envelope moved into a role, which
  ADR 0013 records). ADR 0009
  (request-side controls are themselves dialect-aware parameters surfaced via a
  value object — same shape as the generation-parameter block split).
- **CONTEXT.md** gets a new entry, "Request-side generation parameters
  (the per-dialect block)", placed between the existing "Request-side
  controls" and "Response-side observability" sections. The vocabulary is
  fixed without restating the rationale (link only). *Renamed 2026-08-17
  (karr #82): the entry first shipped under the audit nickname "RuntimeKnobs
  split", which collides with the real `Langertha::Role::RuntimeKnobs` (ADR
  0012) — the canonical term is now* **generation-parameter block**.
- **Comment updates** in `Engine::OpenAIBase.pm:28-33` and
  `Engine::AnthropicBase.pm:21-25` — the per-direction comments carry a pointer
  to this ADR plus a single-line reference to the partner direction. Kept out
  of this ADR's own diff to stay scoped; *done since* in karr #80 (9715189).
- **Git-native kanban.** ADR 0015 closes doku-audit findings 4 (the
  `-excludes` canon) and 6 (the per-family capability correction), and
  makes finding 5 (the generation-parameter block asymmetry) an *accepted*
  asymmetry rather than silent drift. Follow-up work:
  - karr #68 finding-1/2 implementation: update the per-direction code
    comments in `OpenAIBase.pm` / `AnthropicBase.pm` to point at this
    ADR + the partner direction. *Done* — karr #80 (9715189).
  - Generation-parameter helper extraction — *done* as the
    `generation_kwargs_for` method on `Langertha::Engine::Remote`
    (`Engine::Remote.pm:147-182`), per karr #98; decision 3's open
    design question closed by karr #111. The wire-agnostic kwargs
    share a method on the common ancestor; dialect-specific
    positioning (`temperature`, `response_format`, `seed`, `knobs_kwargs_for`,
    `inference_geo`, …) stays inline because each dialect positions
    those fields at a specific place in the body. Remaining follow-up,
    if any: other dialect families (Gemini, Ollama, TranscriptionBase,
    AKI, LMStudio native) adopting the helper once they grow a
    `chat_request` that emits the same wire-agnostic kwargs.

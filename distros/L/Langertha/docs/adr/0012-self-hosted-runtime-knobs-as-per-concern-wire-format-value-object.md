# ADR 0012 — Self-hosted runtime knobs are a per-concern wire-format value object

- Status: accepted
- Date: 2026-08-13
- Tags: engines, roles, value-objects, wire-format, self-hosted, prefix-cache, capabilities

## Context

The self-hosted OpenAI-compatible engines — vLLM, SGLang, llama.cpp — expose runtime
knobs that influence throughput / latency without changing model identity. The original
karr #31 scope listed three candidate surfaces: prefix caching, speculative decoding,
and continuous batching. Research (karr #31, `langertha-llm-advisor`, live-verified
2026-08-13) corrected that scope before implementation:

- **Speculative decoding is restart-only on all three engines** — vLLM
  `--speculative-config`, SGLang `--speculative-*`, llama.cpp `--spec-draft-*` — never a
  per-request knob. Modeling it as a request field would have shipped a dead field.
- **Continuous batching is an internal scheduler flag**, not a user knob at all.
- The genuinely per-request surface is **prefix-cache isolation/reuse controls only**:
  vLLM `cache_salt`; SGLang `cache_salt` / `extra_key` / `priority` /
  `return_cached_tokens_details`; llama.cpp `cache_prompt` / `n_cache_reuse` / `id_slot`.

The three engines share the OpenAI wire envelope (all extend `OpenAIBase`,
`tool_wire_format=openai`) yet accept **disjoint knob field sets** — no two of them take
the same field. This is the same problem ADR 0009 solved for reasoning and prompt caching
(normalized intent in, provider-shaped field out), with one twist: there is no generic
"OpenAI knob dialect" to default to, because the OpenAI cloud API has no such knobs at all.

## Decision

The self-hosted runtime knobs are modeled as a **per-concern wire-format quartet** — the
third such concern after reasoning and prompt caching (ADR 0009) — implemented in commit
`bb782c1`:

1. **A dedicated `knob_wire_format` tag** — the enum `vllm` | `sglang` | `llamacpp` —
   deliberately separate from `tool_wire_format` and from `reasoning_wire_format` /
   `cache_wire_format`. The three engines share the OpenAI wire envelope, so
   `tool_wire_format` cannot express the dialect; and the knob dialect is a different
   concern than reasoning or caching, so those tags cannot either. Per-concern tags
   (ADR 0009) extend to a third concern.

2. **No shared default for `knob_wire_format`** — unlike `reasoning_wire_format`'s
   `openai` default. An `openai` knob dialect does not exist (the OpenAI cloud API has no
   prefix-cache knobs), so a forgotten tag must **fail loudly, not silently no-op**. The
   lazy builder `_build_knob_wire_format` in `Langertha::Role::RuntimeKnobs` croaks,
   naming the engine class, the role, and the missing tag. Each engine overrides the
   builder (`sub _build_knob_wire_format { 'vllm' }`) — the codebase convention for
   wire-format tags.

3. **A value object owns the wire shape.** `Langertha::Runtime::Knobs` carries seven
   normalized attributes (`prefix_cache_salt`, `cache_prompt`, `n_cache_reuse`, `id_slot`,
   `priority`, `return_cached_tokens_details`, `extra_key`), per-dialect serializers
   `to_vllm` / `to_sglang` / `to_llamacpp` that **clamp away** knobs the wire does not
   accept (returning an empty list when nothing applies), and a `to($fmt)` dispatch that
   croaks on an unknown tag. This is exactly the instinct of ADR 0001 / ADR 0009 — the
   per-provider placement of the fields lives in one reviewable place, not scattered
   across engines.

4. **A predicate-gated role holds the normalized attributes.** `Langertha::Role::RuntimeKnobs`
   exposes the seven knob attributes plus `knobs_kwargs_for(%args)`, which merges
   per-request controls over the configured attributes **per key** (a control from the
   `chat_f` channel, karr #46, beats the engine attribute; keys the caller does not carry
   fall back to the attributes). `knobs_kwargs` is the no-override convenience form.

5. **The seam is a `can`-guarded sibling call.** `Role::OpenAICompatible`'s
   `chat_request` / `chat_stream_request` emit
   `( $self->can('knobs_kwargs_for') ? $self->knobs_kwargs_for(%$controls) : () )` next to
   the existing `reasoning_kwargs_for` / `prompt_cache_kwargs_for` calls — zero impact on
   the ~20 engines that do not compose the role.

6. **The knobs serialize as top-level request-body fields via the value object, not a raw
   `extra_body` side-channel** — ADR 0004: no `extra_body` passthrough exists, and
   `generate_json_body` flattens every kwarg to a top-level body key, so the value
   object's returned kwargs are exactly what reaches the wire.

7. **Engines vLLM / SGLang / LlamaCpp compose the role and set their wire tag.**

8. **Capability `prefix_caching` is registered in `%ROLE_TO_CAPS`** (ADR 0002), with the
   semantics **"the wire accepts prefix-cache isolation/reuse controls"** — *not* "prefix
   caching is on". Whether the server actually caches is launch state the client cannot
   observe (vLLM `--enable-prefix-caching`, SGLang `--enable-mixed-prefill` /
   `--enable-prefix-caching`, llama.cpp `--cache_prompt`); the flag only says the request
   body may carry the knobs.

9. **`Langertha::Response` gained `cached_tokens`** (`Maybe[Int]`, predicate
   `has_cached_tokens`), populated from `usage.prompt_tokens_details.cached_tokens` on the
   OpenAI-compatible wire (SGLang with `return_cached_tokens_details` enabled, and other
   servers that emit the detail block).

10. **`chat_f` routes the seven knob names through `%CANONICAL_CONTROLS`** (karr #46), so
    the canonical names translate to wire names via the value object
    (`prefix_cache_salt` → `cache_salt` on vLLM/SGLang) instead of being spread as raw
    target-wire kwargs.

## Rationale

**Why a dedicated tag.** The three engines agree on `tool_wire_format=openai` — the
agreement that tag encodes (which tool dialect) says nothing about which knob fields the
server accepts, because the three accept *disjoint* sets. This is the same argument ADR
0009 makes for reasoning: wire dialect is per concern, so the tag is per concern. The knob
concern is distinct from reasoning and caching, so it gets its own tag rather than
overloading either sibling.

**Why no shared default.** `reasoning_wire_format` can default to `openai` because an
OpenAI reasoning dialect exists. No OpenAI knob dialect exists — the cloud API has no
prefix-cache knobs — so a default would be a lie that silently ships a request with no
knobs and no error. The croak is the fail-loud discipline (house rule 10): an engine that
forgets its tag dies at first use with a message naming the role and the missing tag,
instead of quietly degrading to a no-op. The `to($fmt)` croak on an unknown format is the
same guard at the value-object layer.

**Why speculative decoding and continuous batching are deliberately NOT modeled.** Both
are restart-only server-launch configuration on all three engines (speculative decoding)
or internal scheduler state (continuous batching). Modeling them as per-request knobs
would have shipped dead request fields — exactly the class of bug ADR 0004 names. The
research (karr #31, llm-advisor, live-verified 2026-08-13) corrected the original ticket
scope; the ADR records the correction so a future review does not re-expand the surface.

**Why top-level body fields, not `extra_body`.** ADR 0004 establishes that no
`extra_body` side-channel exists and that the request body *is* the spread of kwargs. The
value object's returned kwargs are top-level body keys by construction — the same
mechanism `reasoning_kwargs_for` / `prompt_cache_kwargs_for` use.

**Why the capability semantics.** ADR 0002 / ADR 0009 establish that a capability flag
means *the wire accepts the field*, not that any given model or server honors it. Prefix
caching is the extreme case: the client cannot observe whether caching is on at all, so
the flag can only truthfully mean "the request body may carry the knobs".

**Design constraints worth recording.** `prefix_cache_salt` is a **cache-ISOLATION
feature, not a performance knob** — a security feature for multi-tenant privacy and
timing-attack mitigation: only requests sharing a salt reuse each other's KV blocks, so a
random per-request salt *reduces* cache reuse (the opposite of a cache-warming hint), and
requests that want to share cached prefix blocks must carry the same salt. vLLM's
`cache_salt` requires vLLM v1.x; older servers silently ignore unknown fields (a no-op,
not an error). llama.cpp's `n_cache_reuse` is **counter-intuitive**: `0` means reuse all
cached tokens, higher values *limit* reuse.

## Consequences

- **A new self-hosted engine** = compose `Role::RuntimeKnobs`, override
  `_build_knob_wire_format`, and — if it accepts a field the value object does not yet
  know — add one attribute + one serializer branch. No engine-side placement code.
- **A new knob field** = one attribute on the role and the value object, one branch in the
  relevant `to_<fmt>` serializer. The clamping (which wire accepts which knob) is the
  value object's private knowledge.
- **The croak-on-forgotten-tag is the fail-loud guard.** An engine that composes the role
  without a tag dies at first use; a `to()` call with an unknown format dies at the value
  object. There is no silent no-op path.
- **`prefix_caching` means "the wire accepts the controls", not "caching is on".** Callers
  must not read it as a server-state probe.
- **`cached_tokens` is populated only on the non-streaming OpenAI-compatible path** so far
  — the streaming path does not yet lift the detail block (see Future work).
- Cross-links: **ADR 0001** — the value-object-owns-the-wire pattern this concern follows.
  **ADR 0002** — `prefix_caching` is registered in `%ROLE_TO_CAPS` with the
  wire-accepts-the-field semantics. **ADR 0004** — the knobs are top-level request-body
  fields, not an `extra_body` side-channel. **ADR 0006** — the tag defaults off the engine
  hierarchy, but per concern (here the engines set it explicitly because no shared default
  exists). **ADR 0009** — the per-concern wire-format quartet this concern extends to a
  third member.

## Future work

- **Streaming `cached_tokens`.** The streaming path does not yet populate
  `Response.cached_tokens` from the streamed usage block. Tracked on the karr board (#61).
- **`CONTEXT.md` does not yet name `knob_wire_format` / `Langertha::Runtime::Knobs`.** As
  with ADR 0009's future work for reasoning/cache, extending the domain language so this
  sibling seam is a first-class term (not just an analogue of the tools seam) would keep
  the vocabulary truthful. Candidate karr follow-up.

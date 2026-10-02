# ADR 0011 — Response timing seam: engine-agnostic seconds + engine-native stages, layered first-write-wins

- Status: accepted
- Date: 2026-08-10
- Tags: response, timing, observability, langfuse

## Context

The tool wire-translation lane (ADR 0001 / 0003 / 0010) and the request-side controls
(ADR 0009) are well-modeled. Response-side observability — specifically *timing* — was
not. `Langertha::Response->timing` existed as a HashRef populated only by Ollama (which
fills it from its native `*_duration` nanosecond fields). No client-measured timing,
no standard accessors, no first-class surface for the Langfuse/Prometheus downstream
that the project already advertises.

The patch that motivates this ADR landed in commit `5cd8c02`. It added:

1. `ttft_seconds` / `total_seconds` accessors + `has_ttft` / `has_total` predicates
   (Float, seconds, engine-agnostic).
2. `Role::Chat` client-side measurement: `Time::HiRes tv_interval` around sync
   `simple_chat`; `ttft_seconds` set at the first chunk in async
   `simple_chat_stream_realtime_f`.
3. `Role::HTTP::execute_streaming_request` returning `($chunks, $timing)`.
4. `Engine::Ollama` deriving `*_seconds` from `*_duration` (ns) while preserving the
   original keys for back-compat.
5. `Role::Langfuse::around simple_chat` anchoring `end_time` and
   `completion_start_time` to response-side timing so the generation event spans the
   real call window.
6. `Langertha::Response::clone_with` refactored from a hand-rolled attribute list to
   Moose-metaclass iteration (karr #5 regression gate — sequential `clone_with` was
   dropping the `timing` HashRef, e.g. timing → tool_calls → rate_limit chains).

The patch is review-shipped, the behavior is locked in tests, but the *shape decisions*
are ADR-worthy. They split into four:

1. **Two classes of timing keys in one HashRef.** Engine-agnostic (standard) and
   engine-native (stage). They share one attribute, no separate `Langertha::Response->
   measured_timing` vs `provider_timing`.
2. **First-write-wins merge policy.** Provider-supplied values trump client-measured.
3. **Sync-vs-async observability gap.** `LWP::UserAgent` (sync) buffers the streaming
   body before parsing, so a true `ttft_seconds` is not observable in that path. The
   async `IO::Async` path delivers chunks incrementally and can.
4. **`clone_with` metaclass iteration.** Every future `is => 'ro'` Response attribute
   with a `predicate => 'has_*'` is auto-carried through `clone_with`. New contract for
   Response authors.

The review also surfaced a follow-up question (karr #32) about whether the first-write-
wins policy is the *right* policy for `total_seconds` specifically — see
[Consequences](#consequences) and the linked ticket.

## Decision

### 1. One `timing` HashRef with two classes of keys

`Langertha::Response->timing` is a single `HashRef[Num]` that holds both:

- **Engine-agnostic standard keys** — populated by the framework on every response,
  via `Role::Chat` / `Role::HTTP` measurement:
  - `ttft_seconds` — Float, seconds. Time from request send to first parsed chunk.
    `undef` for sync calls and for engines that did not record the metric.
  - `total_seconds` — Float, seconds. End-to-end wall-clock from before
    `user_agent->request` (sync) or `do_request` (async) to after the response body
    was fully consumed. `undef` when the engine did not record the metric.

- **Engine-native stage keys** — populated by individual engines from wire data:
  - Currently: Ollama `total_seconds` / `load_seconds` / `prompt_eval_seconds` /
    `eval_seconds` (Float, seconds) plus the original `*_duration` keys in nanoseconds
    preserved for back-compat.
  - Future engines add engine-specific keys the same way. No engine-native key is
    reserved by the framework. **Narrowed by the Update below (karr k126): no
    engine-native key *stem* is reserved, but the `_seconds` *suffix* is.**

The two classes coexist in the same HashRef and are accessed by the same
`$response->timing` accessor. Engine-agnostic keys take precedence in the public
accessor API (`$response->ttft_seconds`, `$response->total_seconds`); engine-native
keys are read through the raw hashref (`$response->timing->{prompt_eval_seconds}`)
or, where stable enough, by convenience methods on the engine.

`has_timing`, `has_ttft`, `has_total` are the standard predicates. They probe the
HashRef, not the attribute — they are plain subs, not Moose `predicate => ...` (which
operates on whole attributes and cannot express "this key exists in the hashref").

### 2. First-write-wins merge via `Role::Chat::_merge_timing_field`

```perl
sub _merge_timing_field {
  my ( $existing, $key, $value ) = @_;
  my $t = $existing ? { %$existing } : {};
  $t->{$key} = $value unless exists $t->{$key};
  return $t;
}
```

A new private helper in `Role::Chat` that shallow-copies an existing timing hashref
and only writes the new key if it does not yet exist. Used in both `simple_chat`
(sync) and `chat_f` (async) when layering client-measured timing onto a response
that may already carry engine-native keys:

```perl
$result = $result->clone_with(
  timing => _merge_timing_field( $result->timing, total_seconds => $elapsed ),
);
```

Rationale: provider-reported durations (e.g. Ollama's `total_duration / 1e9`) are
authoritative for *model-side* time and exclude network jitter, which is what
latency dashboards want. First-write-wins keeps the engine's authoritative value
intact when it is already there, and adds the client measurement as a *new* key
when it is not — so no information is lost.

Open question (karr #32): for the standard key `total_seconds` specifically, this
means Ollama's server-reported value shadows the client-measured round-trip.
Round-trip latency is recoverable from the difference between provider-native and
client-measured when both are present, but it is not first-class on the Response.
Resolution is a deliberate product call — see [Consequences](#consequences).

### 3. Sync vs async observability gap is documented, not papered over

Sync streaming via `LWP::UserAgent` (the default for non-async engines) cannot
observe a true `ttft_seconds` because LWP buffers the entire response body before
`process_stream_data` runs. `Role::HTTP::execute_streaming_request` therefore
returns `($chunks, { total_seconds => $elapsed })` — no `ttft_seconds` key — and
documents the gap in the method's POD:

> C<ttft_seconds> is omitted because L<LWP::UserAgent> buffers the body before
> parsing — switch to the async path for true TTFT.

Async streaming via `IO::Async` (the `chat_f` / `simple_chat_stream_realtime_f`
path) sets `ttft_seconds` at the first chunk and is the only path that exposes it.
The accessor reads `undef` and `has_ttft` returns false for sync responses; callers
must check `has_ttft` before reading.

### 4. `clone_with` iterates the Moose metaclass

`Langertha::Response::clone_with` no longer maintains a hand-rolled attribute
list. It walks `$self->meta->get_all_attributes`, carries forward every attribute
that has a predicate and a read accessor and is not required, and skips any
attribute named in `%overrides` (so the override value reaches `new`).

This fixes karr #5: sequential `clone_with(timing => ...)` then
`clone_with(rate_limit => ...)` was dropping the timing hashref on the second
clone. The new implementation auto-carries `timing` and any other future
attribute, so a chain of `clone_with` calls preserves everything except what the
caller explicitly overrides.

Contract: every future `is => 'ro'` Response attribute added with a
`predicate => 'has_*'` will be auto-cloned. If an attribute is not safe to clone
(e.g. an internal cache that must not propagate across ThinkTag-filtered
responses), the author must add it without a predicate — the contract is explicit
at attribute declaration time.

## Rationale

The split into engine-agnostic and engine-native keys mirrors the request-side
controls (ADR 0009): `Reasoning` / `PromptCache` are the per-concern value objects,
but engines may also write engine-specific keys to the same hash. We keep that
shape on the response side for the same reason — one attribute, two key classes,
symmetry across the request and response seams.

The `_merge_timing_field` helper exists as a *primitive*, not a value object,
because timing is a flat key/value surface (no inbound parser, no outbound
serializer, no per-format branch). The shape does not earn a value object. The
helper makes the merge semantics explicit and testable in isolation
(`t/90_response_timing.t` covers first-write-wins with two subtests).

The sync/async gap is real but localized: the gap exists in the same code path
that has always streamed via LWP, and the fix (move to async) is opt-in per
engine. Documenting it in the POD of `execute_streaming_request` and on
`Response.ttft_seconds` is enough to make it discoverable.

The `clone_with` refactor is a hard regression gate (karr #5 was a real bug
that bit during the timing patch) and the new shape picks up new attributes for
free, at the cost of one line of contract per attribute (predicate-required for
auto-clone). The cost is small; the regression is no longer possible.

## Consequences

- **Open: W1 / karr #32.** `Response.total_seconds` returns Ollama's server-reported
  value (5.0s) in preference to the client-measured wall-clock (5.4s). This is
  intentional (server time excludes network jitter) but silent. Resolution paths
  considered: (A) document the policy and keep first-write-wins; (B) rename the
  Ollama key (e.g. `server_total_seconds`) so client wins; (C) make the policy
  engine-configurable. **Decision deferred** — see karr #32 for the full debate.
  The current ADR accepts first-write-wins as the merge primitive; whether the
  *standard key* `total_seconds` should be the one that wins is a separate,
  smaller question.
- **Langfuse timing is anchored to the wrapper's `$start`, not to wall-clock now.**
  `end_time` and `completion_start_time` use `_langfuse_iso_after($start, $delta)`
  so the generation event spans the actual call window rather than drifting into
  the future. `_langfuse_iso_after` clamps negative deltas (clock-skew safety) and
  rounds to whole milliseconds to match `_langfuse_timestamp`. The current
  end-to-end Langfuse test only checks the predicates, not the actual batch body
  — see karr #33 (T3) for the follow-up.
- **Streaming TTFT is only verifiable end-to-end against a real streaming
  engine.** `t/90_response_timing.t` covers the attribute surface and the
  shape contract of the streaming return tuple, but does not drive a fake SSE
  body through `simple_chat_stream_realtime_f` to assert that `ttft_seconds` is
  set at the first chunk. Follow-up: karr #34 (W10) for the end-to-end test
  with a `Net::Async::HTTP` fake.
- **The route asymmetry named in Decision 3 is a class, not a one-off.**
  `ttft_seconds` exists on the async streaming path and reads `undef` on the
  sync one. The same shape has since turned up on a neighbouring field:
  `Response.thinking` is filled on the non-streaming route (by the dialect
  role's `chat_response`, by `Role::ThinkTag`, or by an engine-scoped lift —
  ADR 0018) while `Langertha::Stream::Chunk` used to carry no `thinking` at
  all, so a streamed call on the very same engine and prompt read `undef`.
  Tracked as karr k129, and **resolved there (commit `74ccc6d`) by exactly the
  policy this ADR set for the class**: `Stream::Chunk` gained a `thinking`
  field with a `has_thinking` predicate, the dialect parsers fill it, and
  `Role::Chat::aggregate_thinking` reassembles it — the same shape as the
  `tool_calls` chunk field and `aggregate_tool_calls`, returned as an additive
  trailing element from `chat_stream_realtime_f`. The gap is documented on the
  accessor and gated behind a predicate; one route no longer silently answers
  for the other. Being an application of the `aggregate_tool_calls` precedent
  and this ADR's stream-path reality (there is no `Response` on the stream
  path), it needed no ADR of its own.
- **Cross-links.** **ADR 0001 / 0003 / 0010** — the tool wire-translation
  seam, which the response-side timing surface parallels (one attribute, two
  key classes, no per-engine specialization at the accessor layer). **ADR 0009**
  — the request-side controls (reasoning / cache) that already follow the same
  shape and informed the design. **ADR 0018** — where a provider's *spelling*
  of a canonical response field is normalized; the timing keys are the case
  where no normalization layer existed and the units diverged (see the Update
  below). `CONTEXT.md` fixes the vocabulary (the "Response-side observability"
  section under "sibling seams" was added in the same release).

## Update (karr k126 — engine-native timing keys share one flat namespace)

Decision 1 closes with "No engine-native key is reserved by the framework."
That sentence quietly assumed engine-native keys are *read* per-engine, by a
consumer who already knows which engine answered. `karr k126` is the first
proof that they are not:

    Engine::Ollama   timing->{total_duration} = 7319258765   # NANOSECONDS
    Engine::AKI      timing->{total_duration} = 0.14         # SECONDS

One flat HashRef, one key stem, two units, no namespace and no unit metadata —
and reading the raw hashref is exactly what this ADR sanctions for stage keys.
A dashboard doing `$response->timing->{total_duration}` was wrong by a factor
of 1e9 depending on which engine replied, and nothing in the framework could
catch it.

Three resolutions were weighed (karr k128):

- **(a) Guidance only** — "prefer the engine-agnostic accessors; engine-native
  keys carry no cross-engine unit guarantee."
- **(b) A unit-bearing suffix convention** — `_seconds` means seconds;
  `_duration` stays nanoseconds and stays Ollama's.
- **(c) Namespace native keys per engine** — `timing->{ollama}{total_duration}`.

**The code follows (b), with (a) as the consumer-facing guidance.** The
`_seconds` suffix is now **reserved and unit-bearing**: any key ending in
`_seconds` is a Float in seconds, engine-agnostic and engine-native alike, and
an engine that reports a stage timing emits it under that suffix — converting
if the wire uses another unit. `*_duration` is *not* a parallel convention: it
is `Engine::Ollama`'s back-compat legacy in nanoseconds, kept because it
shipped, and no new engine adds one. `Engine::AKI` (commit `b4da770`) is the
first engine written under the rule — it emits `total_seconds` and the native
`compute_seconds` from a wire that already reports seconds, and deliberately
emits no raw `total_duration` at all, which is what ended the collision.

Decision 1 is therefore narrowed, not reversed: **no engine-native key *stem*
is reserved; the `_seconds` *suffix* is.** Native keys still share one flat
namespace with no per-engine prefix, so two engines may still land on the same
stem — but under the suffix rule such a collision is unit-compatible, which is
the survivable kind. The one hazard that remains is a `*_seconds` key whose
*meaning* differs across engines (whose clock, which stage); that is a
documentation problem, not a silent 1e9.

(c) was rejected: it would break the shipped Ollama keys and the flat
`HashRef[Num]` type, force `_merge_timing_field` and the Langfuse anchor to
learn a nesting level, and buy nothing the suffix rule does not already give.

This is an amendment in place rather than a superseding ADR because none of the
four shape decisions above changed — one HashRef, two key classes, first-write-
wins, metaclass `clone_with` all stand. Only one sentence of Decision 1 is
narrowed and a hazard is recorded. Contrast ADR 0006 → ADR 0013, where the
placement axis of the thing itself moved and a new number was right.

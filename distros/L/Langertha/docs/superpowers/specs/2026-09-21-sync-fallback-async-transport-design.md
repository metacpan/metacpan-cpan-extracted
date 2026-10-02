# Design Spec — Sync-fallback async transport (karr #188)

- Status: **approved (2026-09-21); ready for implementation plan**
- Date: 2026-09-21
- karr: #188 (this)
- ADRs touched: revisits **0026**'s dependency decision (it added `IO::Async` + `Net::Async::HTTP`
  as `requires`); this makes them `recommends`. A new ADR records the shift once implemented.
- Advisor red-team: N/A for provider reality (internal transport). One provider-facing
  verification point: SSE/chunked streaming over LWP's content callback (see §4, §10).
- Delegation: behavior-relevant core → `langertha-worker` (TDD) after owner approves this spec.
  Orthogonal to the Raider extraction (landed `1e52de0`), its own branch.

## 1. Problem & scope

Langertha's async `_f` methods hard-require an IO::Async event loop and `Net::Async::HTTP`.
ADR 0026 made both explicit `requires`. But the framework only needs them on the async path:
the **sync** path (`simple_chat`, `chat`) already runs over `LWP::UserAgent` (`Role::HTTP`) and
touches neither. So a user who never calls a `_f` method pays for a heavy async stack they never
use, and the async backend is not swappable.

**Goal:** give the `_f` path a synchronous fallback so `IO::Async` + `Net::Async::HTTP` become
`recommends`. When no async backend is available (and none injected), a `_f` call runs the HTTP
**synchronously** over LWP and returns an already-complete `Future`; every `await` on an
already-complete future resolves without an event loop, so the whole chain runs sync and the
caller's `->get` returns immediately. Nobody downstream can tell it was not "really" async — it
degrades to sequential/blocking, nothing more.

**Non-goals:** full loop-agnosticism (swapping IO::Async for AnyEvent/Mojo as the *loop*). This
spec covers the no-loop/sync case and the inject-your-own-client case, which is the bulk of the
value. A pluggable loop layer is a later, separate project (§12).

## 2. The seam today

- `Role::Chat` holds `_async_loop` (lazy_build → `IO::Async::Loop->new`) and `_async_http`
  (lazy_build → `Net::Async::HTTP->new`, `$loop->add($http)`) — Chat.pm:366–387. Both are Moose
  attributes with open `init_arg`, so a client is **already injectable** at construction; only the
  default builder is hardcoded, and the names are private/undocumented.
- The consumption is duck-typed on one contract:
  `_async_http->do_request(request => $req [, on_header => sub {...}]) → Future<HTTP::Response>`
  — non-streaming at Chat.pm:628, streaming at Chat.pm:798 (where `on_header->($response)` returns
  a per-chunk callback).
- `Role::HTTP` already does synchronous HTTP via `LWP::UserAgent`, including provider-error-body
  handling on failed requests.
- `Role::Runtime::MetricsPoll` **duplicates the same seam** (its own `_async_loop`/`_async_http`
  builders + `poll_metrics_f` async / `poll_metrics` sync-wrapper that spins a private loop).

## 3. Design

Introduce a **synchronous HTTP backend** that satisfies the exact `do_request` contract over LWP
and returns `Future->done($response)` — no IO::Async, no loop. Select the backend in one shared
place (extract the fallback logic so `Role::Chat` and `MetricsPoll` share it, ending the
duplication):

1. **injected `_async_http`** (constructor value) → use it verbatim.
2. else **`Net::Async::HTTP` loadable** (`eval { require Net::Async::HTTP }`) → real async client
   (build `_async_loop`, add client) — today's behavior, unchanged.
3. else → **sync LWP shim** + a one-time warning (§5).

`_async_loop` is built **only** on path 2. Path 3 never touches it. `_async_http`/`_async_loop`
become documented, injectable attributes with the stated contract, so "bring your own async
client" is a supported feature rather than an accident of private attributes.

## 4. Streaming bridge (owner: sync streaming is IN)

LWP supports incremental reads: `$ua->request($req, sub { my ($data, $response) = @_; ... })`
fires the callback per body chunk. The sync shim's `do_request(request =>, on_header =>)` maps to
it: on the first content callback, invoke the caller's `on_header->($response)` to obtain the
chunk-sub, then feed every `$data` to that sub; on completion resolve `Future->done($response)`.
This matches Chat.pm:798 exactly, so `_process_stream_buffer` and the chunk callbacks fire live —
incrementally, just blocking. **Verification point:** confirm LWP delivers the `HTTP::Response`
(headers) as the callback's 2nd arg before body chunks, and that chunked/SSE transfer streams
rather than buffering whole (test with a canned chunked responder, §10).

## 5. Fallback detection & warning

Backend selection does `eval { require Net::Async::HTTP; 1 }`. On the sync path, `carp` **once per
process** (package-level flag): *"Net::Async::HTTP not available; Langertha is running HTTP
synchronously (no concurrency). Install Net::Async::HTTP + IO::Async for real async."* An
explicitly injected client never warns.

## 6. Error parity

An LWP failure must surface the same way as a `Net::Async::HTTP` failure — same croak text and the
same provider-error-body append that `Role::HTTP` already does on the sync path. The shim routes
its failures through that shared normalization so callers see identical behavior regardless of
backend.

## 7. Concurrency semantics (honest degradation)

The sync backend is sequential and blocking: multiple `_f` calls awaited "in parallel" run one
after another. This is the accepted trade — documented in the POD of the `_f` methods and of the
backend attribute, so no one mistakes sync-mode for real concurrency.

## 8. cpanfile

`IO::Async` and `Net::Async::HTTP` move from `requires` to `recommends`. `LWP::UserAgent` /
`LWP::Protocol::https` stay `requires` (sync transport + the fallback). A clean `cpanm Langertha`
then installs a working sync-capable core; async users install the two recommends (or `cpanm
--with-recommends`). The new ADR records this reversal of ADR 0026's dependency line.

## 9. Scope

`Role::Chat` **and** `Role::Runtime::MetricsPoll`, via the shared backend-selection helper (both
carry the identical seam; leaving MetricsPoll async-only would make `recommends` dishonest for its
users). Streaming included.

## 10. Testing (TDD, run without the async stack)

Mirror the extraction's `@INC`-block technique to prove the sync path needs neither module:

- **Backend selection:** injected client wins; `Net::Async::HTTP` present → async client chosen;
  blocked via `@INC` → sync shim chosen + exactly one warning captured.
- **Sync non-streaming:** `chat_f(...)->get` returns the correct `Langertha::Response` with
  `IO::Async`/`Net::Async::HTTP` blocked from `@INC`; assert `!$INC{'IO/Async/Loop.pm'}` afterward.
- **Sync streaming:** chunks delivered incrementally through the shim against a canned chunked
  responder; final aggregated content equals the async path's.
- **Parity:** for one canned server, sync and async produce an identical `Response` (content,
  tool_calls, status) and identical error handling on a 4xx/5xx with a body.
- **Warn-once:** only one warning per process across multiple sync `_f` calls.
- MetricsPoll: `poll_metrics`/`poll_metrics_f` work over the sync shim with the async stack blocked.

## 11. Resolved decisions (owner-approved 2026-09-21)

1. **MetricsPoll is in scope** — the same shared backend-selection helper as `Role::Chat`.
2. **Attribute surface:** document the existing `_async_http`/`_async_loop` as the injection
   contract; no rename, no public alias (surgical).
3. **Warning:** once per process.

## 12. Out of scope / future

Pluggable event loop (AnyEvent/Mojo as the loop, real concurrency on a non-IO::Async loop). The
inject-your-own-client seam this spec formalizes is the hook a future loop-adapter layer would
build on; not needed now.

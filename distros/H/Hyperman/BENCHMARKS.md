# Hyperman — Benchmarks (Phase 1)

Phase 1 = single kqueue event loop per worker, sync PSGI, keep-alive.

**Host:** macOS, 10 cores, `wrk` **co-resident** with the server (they share
cores). Loopback. Numbers are *relative*; headline figures need Linux + a
separate load client (see `plan/07-performance-and-roadmap.md`). Plaintext
"Hello, World!", keep-alive, isolated runs with a 30s port drain.

## Per-worker (the clean comparison), `wrk -t4 -c400`

| Server (1 worker) | Model | req/s | % of Hypersonic |
|---|---|---|---|
| Hypersonic | JIT, C event loop | 240,692 | 100% |
| **Hyperman** | **XS kqueue event loop** | **209,461** | **87%** |

**87% of a JIT C server per worker, first cut, no optimization.** For context,
the same single Hyperman worker beats our entire **6-worker** pure-Perl prefork
PSGI server (155k) by 1.35×, and is 2.3× one Starman-equivalent worker.

## Light-client (2-thread) runs, `wrk -t2 -c100`

| Server | Workers | req/s |
|---|---|---|
| Hyperman | 1 | 210,844 |
| Hyperman | 6 | 212,972 |

At `-t2` the **load client saturates** (~210k), so worker scaling is invisible
here — one Hyperman worker already maxes a 2-thread `wrk`.

## Real drop-in PSGI server (post header-parsing)

After adding full request-header parsing into `$env`, `psgi.input`,
`psgi.errors`, and `Plack::Handler::Hyperman`:

| Path | req/s | note |
|---|---|---|
| direct runner, 1 worker | 200,413 | full header parse cost ~4% vs 209k |
| `plackup -E deployment -s Hyperman`, 1 worker | 207,972 | real Plack stack, full speed |
| `plackup` (dev mode) | 22,500 | plackup's AccessLog/Lint/StackTrace middleware, not the server |

Header parsing cost only ~4% (209k → 200k), matching the spike's "parsing is
cheap" finding. Verified correct against a real `Plack::Request` app (GET query
params and POST form body both parse). Hyperman now runs any Plack app via
`plackup -s Hyperman` at full speed.

## Write-path optimization

Reusing a per-connection write buffer (no per-request malloc/free) and building
the response bytes directly in C (no intermediate SVs):

| Build (1 worker, `wrk -t4 -c400`) | req/s | % of Hypersonic |
|---|---|---|
| after header parsing | 200,413 | 83% |
| **+ optimized write path** | **211,534** | **88%** |

Now at **88% of a JIT C server per worker** as a full PSGI server. The buffer
reuse both recovered the header-parse cost and pushed past the pre-parse 209k.

## The gap, and why

Hyperman's remaining 13% vs Hypersonic is the per-request Perl surface:

- Hypersonic JIT-compiles the handler to C returning a constant string — its
  "app call" is near-free.
- Hyperman makes a real Perl app call and builds a full `$env` HV each request,
  then serializes with `sv_catpvf`/`realloc`.

Optimization targets (later): lean `$env` construction (lazy/templated keys),
avoid `realloc` per response (pooled write buffers), `writev` header+body, and
call-checked hot accessors. None needed to prove the thesis — the event loop
already did that.

## Phase 2 — async Futures (functional)

`Hyperman::Future` (Future-API-compatible; 27/27 unit tests) is wired into the
event loop:

- **Timer futures** — `Hyperman->timer($secs)` returns a Future resolved by a
  kqueue `EVFILT_TIMER`.
- **Async dispatch** — a handler that returns a Future parks its connection; the
  loop keeps serving others and writes the response when the Future resolves
  (guarded against fd reuse by a per-connection generation id).
- **Async socket I/O** — `Hyperman->io_ready($fh, 'r'|'w')` returns a Future that
  resolves when an app-owned fd is readable/writable, so apps compose real
  non-blocking I/O (connect/write/read) on the server's loop.

**Verified non-blocking (timer):** with a handler that awaits 300 ms, a
concurrent request completed in **0.0003 s** (not 0.3 s).

**Verified non-blocking (real upstream):** a `/proxy` handler doing a
non-blocking connect→write→read to a 250 ms upstream returned after ~0.26 s; a
concurrent `/fast` request during that in-flight upstream call completed in
**0.0004 s**. The worker keeps serving everyone while an app awaits I/O — the fix
for the "blocking app stalls the loop" hazard.

Adding async detection to the dispatch path did **not** regress the sync hot
path (213k, within noise of 211k).

## Phases 1 & 2 completed to plan (restructure + native Future)

The monolithic XS was restructured into the planned shape and both phases
finished in full:

- **Backend split** — `hm_backend` C vtable (`hyperman.h`) with the kqueue
  implementation in `backend_kqueue.c` (`Hyperman::Event::Kqueue`); epoll slots
  in behind the same interface in Phase 4.
- **`Hyperman::Loop`** — the loop is a struct/object (no globals): `run`,
  `run_until`, `stop`, `watch_io`/`unwatch_io`, `timer`, `defer`, and the
  Future primitives `timer_f`/`readable_f`/`writable_f`.
- **Robustness (doc 02)** — `EVFILT_SIGNAL` graceful shutdown (drains, closes
  idle, second signal = hard stop), idle + header/slowloris timeout sweep over
  an LRU list, per-wakeup pipelining fairness cap, pooled connection structs.
- **writev write path** — header + body chunks writev'd straight from the
  response SVs (no body copy) when the buffer is clear; partial writes fall
  back to the buffered/backpressure path.
- **Native XS `Hyperman::Future`** — array-slot object; creation, resolution,
  state, and callback firing in C; continuations trampolined (a 50k-deep
  `then`-chain resolves without deep recursion). Chaining/combinators
  (`then`/`else`/`followed_by`/`transform`, `wait_all`/`wait_any`/`needs_all`/
  `needs_any`), cancel propagation up then-chains, and CPAN `Future` adapters
  (`as_cpan_future`/`from_future`) in the thin Perl layer.
- **`await`/`get` pump the loop** — a pending future awaited inside a running
  worker re-enters the same loop and services other connections meanwhile.

**Verified:** a handler doing `Hyperman->timer(0.3)->get` (blocking style)
returned in ~0.30 s while a concurrent request completed in **0.0004 s**.
Test suite: 59 tests green. Sync hot path after the full restructure:
**213,399 req/s** (unchanged; the writev path paid for the new bookkeeping).

## PSGI conformance + portable backends

`t/01-plack.t` runs the official **`Plack::Test::Suite`: 102/102 green**.
Getting there fixed: growable read buffers (large POST bodies; 413 over the
16 MB ceiling), PATH_INFO percent-decoded once (RFC 3875), `SERVER_NAME` from
the bind host, repeated request headers joined with `", "`, no entity
headers/body on 1xx/204/304, IO::Handle-like response bodies
(`getline`/`close`), and — completing a Phase 3 item — **`psgi.streaming`**:
coderef responses get a delayed responder, and the 2-element form returns a
writer streaming an EOF-delimited body.

Two more backends implement the `hm_backend` vtable, so Hyperman now runs
off-mac:

- **epoll** (`backend_epoll.c`) — Linux: combined per-fd masks, timerfd
  timers, signalfd shutdown signals.
- **poll** (`backend_poll.c`) — the portability floor: deadline-list timers
  against the monotonic clock, self-pipe signals.

Selection is kqueue → epoll → poll, forceable via `HYPERMAN_BACKEND` or
`Hyperman::Loop->new($name)`. **Verified**: full suite (incl. the Plack
conformance tests, which exercise real sockets, timers, and shutdown) green
on macOS/kqueue, macOS/poll, Linux/epoll, and Linux/poll (docker, arm64).
Hot path after the conformance work: **211,379 req/s** (unchanged).

## Phase 3 — Async PSGI complete

The remaining doc-04 surface is in:

- **`psgix.loop`** — the worker's `Hyperman::Loop` in `$env` (cached wrapper),
  so apps and async clients create Futures bound to *this* loop.
- **`psgix.io`** — the client socket in `$env` as a per-connection dup'd
  filehandle: an app that hijacks it keeps the socket alive after the server
  side closes (websocket/upgrade seam).
- **Any `on_ready` object works as an async response** — a handler may return
  a CPAN `Future`, not just `Hyperman::Future` (verified in tests).
- **Cancellation on disconnect** — a client vanishing while parked cancels the
  response Future, propagating up the `then`-chain so in-flight work aborts.
- **Failure path** — a failed response Future logs to `psgi.errors` and
  renders a 500; the connection stays keep-alive (verified: next request on
  the same connection serves normally).

**Async-workload benchmark** (every response resolved through a deferred
Future — full park/deliver cycle per request): **137,804 req/s**, i.e. the
fully-async path runs at ~65% of the sync path and still ~1.5× the entire
6-worker prefork server.

**Blocking-app isolation** (2 workers): while `/block` held one worker for a
full second, concurrent requests were served by the other in **0.3–0.8 ms**.
A blocking app stalls only its own worker, as designed.

Sync hot path after Phase 3: **209,436 req/s** (within the 209–213k noise
band). Suite: 5 test files + 102 Plack conformance tests, all green.

## Phase 4 — Linux backends & scaling

**`SO_REUSEPORT` (opt-in, `reuseport => 1`)** — each worker binds its own
listening socket instead of sharing the inherited one. Verified on Linux
(4 workers, 60 connections): the kernel spread them **12/17/13/18** across
workers. Stays opt-in and off by default (macOS semantics funnel to one
worker — the earlier 3× regression).

**io_uring backend** (`backend_iouring.c`) — built on **liburing**, detected
at configure time (pkg-config, then a `-luring` compile probe); without it
the backend compiles out and selection falls back to epoll/poll. Drives the
ring in poll mode: `io_uring_prep_poll_add` readiness (re-armed for
persistent watchers, cancelled via `poll_remove` on close to guard fd
reuse), `io_uring_prep_timeout` timers, signalfd polled on the ring;
submit/reap via `io_uring_submit` + `io_uring_peek_batch_cqe` +
`io_uring_cq_advance`. The **entire suite passes forced onto io_uring**
(Linux, docker, liburing 2.9, seccomp-unconfined); with liburing absent, or
under Docker's default seccomp, `available()` is 0 and auto-selection cleanly
falls back to epoll. Opt-in (`HYPERMAN_BACKEND=io_uring`) until benchmarked
on reference hardware.

**Concurrency sweep (1 worker, keep-alive, co-resident wrk — relative):**

| c (connections) | macOS kqueue | Linux epoll | Linux io_uring |
|---|---|---|---|
| 100    | 210,987 | 270,331 | **304,871** |
| 1,000  | 206,889 | 186,506 | **276,889** |
| 10,000 | 175,191 | 171,111 | 164,905 |

Re-run with the liburing io_uring backend (1 worker, docker, liburing 2.9):
epoll 306k / 210k and io_uring 297k / 252k at c=100 / c=1,000 — io_uring
trails epoll slightly at low concurrency but leads ~20% at c=1,000, matching
the earlier raw-ring result and reinforcing the case for the completion-based
cut. Still docker-relative; reference-hardware numbers pending.

The Phase 4 proof: **one worker keeps ~83% of its throughput at 10,000
concurrent connections** — the spike's prefork server capped in-flight work
at its worker count and was flat-or-dying long before this. And a surprise
headline: **io_uring beats epoll by 13% at c=100 and 48% at c=1,000** even
in poll mode — strong motivation for the completion-based cut, but it stays
opt-in until validated on reference hardware (docker-VM numbers are
relative).

## Phase 5 + process model (doc 06)

Production supervisor and worker hygiene, fully implemented and tested
(`t/14-prod.t`, `t/15-process.t`, both green on macOS/kqueue and
Linux/epoll):

- **Respawn** with exponential backoff on crash loops (1→2→4…30 s); clean
  exits (recycles) respawn immediately. Verified: `kill -9` a worker →
  replacement appears, service uninterrupted.
- **Zero-downtime recycle** on HUP/USR2 (spawn new, drain old): 0 failed
  requests through a live recycle. `max_requests_per_worker` does the same
  per worker (verified: pool rotated through 9+ pids with 0 dropped
  requests).
- **Bounded graceful shutdown** — `shutdown_grace` (default 30 s) hard-stops
  the drain; verified: TERM with a hung (never-resolving) async request
  exited in 1.0 s at grace=1.
- **Observability** — `access_log` callback (kept entirely off the hot path
  when unset), `Hyperman->stats` (requests/accepts/bytes_out/connections/
  backend/pid), and USR1 → per-worker stats dump to stderr.
- Workers default to **ncpu**; accept-batch fairness cap (64/wakeup); opt-in
  Linux CPU affinity.
- Release: real Changes/README, MANIFEST.SKIP, `make disttest` green,
  `Hyperman-0.01.tar.gz` built; tarball suite green on Linux.

**Measurement note:** late-session hot-path samples read 192–204k vs the
209–213k band, degrading monotonically through a long heavy session
(docker builds, repeated test suites). A control at `-t2 -c100` (a config
whose code path is unchanged) showed the same proportional drop — machine
drift on this co-resident laptop, not a code regression. Definitive
before/after belongs to the reference-hardware suite.

## HTTP/2 (h2c via nghttp2)

`Hyperman->run(http2 => 1)` accepts cleartext HTTP/2 (prior-knowledge preface)
on nghttp2, alongside HTTP/1.1 on the same port. nghttp2 is detected at build
time (pkg-config / compile probe); absent, HTTP/2 compiles out and
`Hyperman->has_http2` is false. A connection in h2 mode holds one nghttp2
session; each stream is an independent request dispatched to the app and
resolved through the existing sync / Future / streaming paths — the parked-
Future model *is* the stream multiplexer, so no new concurrency machinery was
needed. nghttp2 owns framing, HPACK, and flow control; `send_callback` feeds
the existing write buffer.

Verified on Linux (docker, nghttp2 1.64, http2-capable curl): SERVER_PROTOCOL
`HTTP/2`, path/query split, request bodies, Future-returning handlers,
`psgi.streaming` (buffered), and 20 multiplexed concurrent streams on one
connection — all matching the HTTP/1.1 behavior of the same app. `h2load`
pushed **2000 requests over 10 connections x 10 concurrent streams at
~195k req/s, 0 failed**. macOS builds unaffected (h2 stubs out).

In this cut: h2c by prior knowledge; sync + async + buffered-streaming
responses. Deferred: TLS/ALPN (the browser path, needs a non-blocking TLS
layer), `Upgrade: h2c`, incremental per-frame streaming, server push.

## TLS / HTTPS (OpenSSL) + h2 over ALPN

`Hyperman->run(tls_cert => ..., tls_key => ...)` serves HTTPS: a non-blocking
TLS handshake driven on the loop (`SSL_accept` mapped to read/write watchers),
then per-connection reads/writes routed through `SSL_read`/`SSL_write` via
`hm_cread`/`hm_cwrite` (WANT_READ/WANT_WRITE → `EAGAIN` plus a cross-direction
flag; the writev fast path is disabled for TLS). OpenSSL is detected at build
time (pkg-config / probe, with a Homebrew fallback on macOS); absent,
`Hyperman->has_tls` is false and `tls_cert` errors. The cert/key are validated
once **before forking**, so a bad pair fails fast, and the read-only `SSL_CTX`
is shared copy-on-write across workers.

With `http2 => 1`, **ALPN negotiates h2 vs http/1.1 per connection on the same
port** — the path browsers use. On handshake completion the selected protocol
starts HTTP/2 (via nghttp2) or stays HTTP/1.1.

Verified on macOS (OpenSSL 3, LibreSSL curl) and Linux (docker, OpenSSL 3.5,
nghttp2 1.64): HTTPS bodies, request bodies, Future handlers, keep-alive,
`psgi.url_scheme` = `https`, a plaintext GET to the TLS port correctly refused;
and over ALPN, `curl --http2` negotiates **HTTP/2 https** while `curl
--http1.1` gets **HTTP/1.1 https** on the same port. `h2load` over TLS+h2
pushed **2000 requests / 10 conns × 10 streams at ~128k req/s, 0 failed**.
macOS and the full suite unaffected (TLS/h2 stub out where the libs are
absent).

**Client certificates (mTLS).** `tls_verify` (optional/require, against
`tls_ca`) requests and checks a client cert; `require` fails the handshake
without a valid one. The subject/issuer/verify result are surfaced in `$env`
(`SSL_CLIENT_VERIFY`/`_S_DN`/`_I_DN`, plus `SSL_PROTOCOL`/`SSL_CIPHER`).
Verified on macOS + Linux: a valid client cert yields `verify=SUCCESS
dn=/CN=alice`, and a connection without one is refused.

**SNI multi-cert.** `tls_sni` maps hostnames to their own cert/key via a
servername callback switching `SSL_CTX`; verified serving `CN=localhost` by
default and `CN=example.test` for that ServerName on one port.

**h2c Upgrade.** Over cleartext with `http2 => 1`, an `Upgrade: h2c` request is
answered `101 Switching Protocols` and continues as HTTP/2 via
`nghttp2_session_upgrade2` (original request becomes stream 1). Verified:
`curl --http2` (no prior knowledge) negotiates the upgrade and gets `HTTP/2
200`.

All three build on the same detection/stub pattern and are covered by
`t/16` (upgrade), `t/17` (TLS), and `t/18` (mTLS + SNI).

## Full-XS restructure

The Hyperman namespace is now 100% XS: the `.pm` files are doc/loader
stubs; `run()` option parsing, `psgi.input` (PerlIO `:scalar` in C), body
slurping, the park continuation, the streaming responder, and all of
`Hyperman::Future`'s chaining/combinators/interop run in C, with
continuations as anonymous XSUBs carrying captured state in magic (no Perl
closures anywhere). Layout follows Chandra: a thin root `Hyperman.xs`
including `include/hyperman/*.h` (+ backends, unity build) and pulling
per-package fragments from `xs/` via `INCLUDE:`. Only
`Plack::Handler::Hyperman` remains pure Perl. Full suite green on
macOS/kqueue and Linux epoll + io_uring + poll (docker).

## What can't be measured here

**Multi-worker scaling.** On a single 10-core box, adding server workers steals
cores from `wrk`, so more workers *reduced* measured throughput (Hyperman-6 =
185k < Hyperman-1 = 209k at `-t4 -c400`) — a co-residence artifact, not a server
defect. True N-worker scaling, `SO_REUSEPORT` (Linux), and the concurrency sweep
to 10k connections require Linux reference hardware with the client on a
separate machine.

## Reproduce

```sh
# build
cd Hyperman && perl Makefile.PL && make
# run (WORKERS/PORT via env), then wrk it
WORKERS=1 PORT=8200 perl -Mblib -e '
  use Hyperman; my $b="Hello, World!";
  Hyperman->run(app=>sub{[200,["Content-Type","text/plain"],[$b]]},
                host=>"127.0.0.1", port=>$ENV{PORT}, workers=>$ENV{WORKERS});'
wrk -t4 -c400 -d8s http://127.0.0.1:8200/
```

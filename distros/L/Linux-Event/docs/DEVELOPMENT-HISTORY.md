# Development History

This file preserves historical engineering decisions and the benchmark/optimization phase notes that previously occupied the project README. It is not public API documentation; current contracts are in module POD and the design guides.

## 0.118 release preparation and October 2026 research decisions

**Snapshot: 2026-11-01.** `main` is Linux::Event **0.118**,
prepared for publication; CPAN remains at **0.117** pending upload. The four original
reactor-contract milestones in the [1.000 roadmap](V1-ROADMAP.md)
were implemented: foreign-loop `poll_fd()/poll()`, `defer()`,
resource-aware managed `fork()`, and native Inotify. Version 0.118
then merged callback-safe `defer_fork()` ([PR #35](https://github.com/haxmeister/perl-linux-event/pull/35))
and native ordered Stream `sendfile()` ([PR #39](https://github.com/haxmeister/perl-linux-event/pull/39)).
Release preparation was approved on 2026-11-01; tagging, a GitHub
release, and CPAN upload still require completion and verification.

This section records experiments **already completed**, not
proposals to begin new work. All numbers are workload-specific and
should not be extrapolated into universal benchmarks.

### EPOLLEXCLUSIVE — investigated, integration deferred

[Research PR #36](https://github.com/haxmeister/perl-linux-event/pull/36)
implemented an opt-in exclusive epoll registration for fork-shared
Listeners, including parent/child rebuilding, pause/resume ADD/DEL,
rollback, reentrancy, and lifecycle regressions. Kernel and short
real-Stream tests cut wasted epoll wakeups but could leave a few
workers handling most burst connections. `SO_REUSEPORT` offered
more even distribution in these short tests but is a different
socket ownership model.

A first sustained local benchmark incorrectly used TCP reset closes,
triggering a Stream error on every completed response. Its throughput
figures were discarded and the client was fixed to wait for ordinary
TCP FIN. The corrected v2 local quad-core dataset comprised
**5,694,682 fully acknowledged requests**, with no losses or Stream
errors. In five-repeat four-worker comparisons, 0-us work produced
ordinary shared / exclusive / reuseport rates of
**10,684 / 11,120 / 10,573 replies/s**. With 150-us synthetic work,
they were **7,903 / 6,951 / 7,448 replies/s**: exclusive was
**12.0% slower** than ordinary shared in that case. Sustained fairness
was above 0.998, unlike short-burst imbalances.

**Decision made after the corrected run:** stop investigating
`EPOLLEXCLUSIVE` for now, leave the opt-in prototype on draft PR #36,
and do not merge or make it a default. The benchmark runner and
[its instructions](https://github.com/haxmeister/perl-linux-event/blob/feature/epollexclusive-evaluation/bench/experiments/EPOLLEXCLUSIVE-LOCAL.md)
remain reproducible; the supplied local data was not stored in this
public repository. Reopen only for a compelling real shared-listener
workload and stronger evidence.

### recvmmsg() — investigated, integration deferred

[Research PR #37](https://github.com/haxmeister/perl-linux-event/pull/37)
implemented and tested a bounded receive-batch prototype, preserving
the public Datagram callback and per-packet contracts.
[Full branch CI passed](https://github.com/haxmeister/perl-linux-event/actions/runs/41133753891).
The local quad-core comparison verified **5,280,000 packets** in
**150/150 completed trials**, with no missing or corrupted data.
The complete Loop/Datagram callback path saw approximately 2.5–5.1%
less receive CPU at 64 B and 1.0–2.8% less at 1,400 B, but
**1.9–2.8% more CPU at 8 KiB**. Serial echo did not show a
dependable gain.

**Decision:** do not merge the prototype or enable it by default;
keep PR #37 and its
[benchmark guide](https://github.com/haxmeister/perl-linux-event/blob/feature/udp-recvmmsg-evaluation/docs/UDP-RECVMMSG-EVALUATION.md)
as research. This decision is about `recvmmsg()` receive batching;
there has been **no separate `sendmmsg()` transmission experiment**.

### sendfile() / splice() — researched; sendfile integrated

[Research PR #38](https://github.com/haxmeister/perl-linux-event/pull/38)
benchmarked copied file-to-TCP transfer, `sendfile()` and
`splice()` using real TCP byte-integrity tests. The local
five-repeat run completed **90/90 transfers without corruption**;
for 200 KiB and 1 MiB files `sendfile()` reduced sender CPU per
MiB by about **79–80%** versus copying. That evidence led to a
narrow native Stream `sendfile()` with ordered file segments,
existing backpressure, source-fd ownership, TLS rejection, and a
private 64 KiB file-drain fairness budget. It merged into `main`
via [PR #39](https://github.com/haxmeister/perl-linux-event/pull/39)
at `f219f24f278cdb1319a38402d3a9a35f61523e08`, after
[ten green core CI jobs](https://github.com/haxmeister/perl-linux-event/actions/runs/41166889428)
and the [actual Stream benchmark](https://github.com/haxmeister/perl-linux-event/actions/runs/41166889422).
[Post-merge CI](https://github.com/haxmeister/perl-linux-event/actions/runs/41208249334)
also passed. See [the finished Stream contract](STREAM-SENDFILE-DESIGN.md).

`splice()` remains only in the syscall comparison, not the
public Stream API. A socket/pipe relay capability would require
a new workload and independent semantics. Do not confuse this
intentional separation with unfinished `sendfile()` work.

### Other explicit decisions and unfinished work

- **Netlink:** the architecture was approved in
  [PR #33](https://github.com/haxmeister/perl-linux-event/pull/33):
  minimal `Linux::Event::Kernel::Netlink` in core and a separate
  `Linux::Event::Netlink` distribution for routes and other families.
  Both are **not yet implemented**; work was deliberately deferred.
- **`sendmmsg()`:** never implemented or benchmarked independently.
  Only investigate when a concrete queued transmit workload warrants it.
- **`fanotify`, UDP packet metadata/error queues/GSO/GRO,
  `AF_VSOCK`, SocketCAN, AF_PACKET and advanced TCP hints:**
  roadmap candidates, not completed core experiments.
- **TLS native-consumer retirement follow-up:**
  [draft PR #34](https://github.com/haxmeister/perl-linux-event/pull/34)
  has focused regression-only coverage and **no production fix**.
  Its core-only tests did not reproduce the reported HTTP selector
  crash; disposition of this test PR remains separate from the
  Linux-native expansion decisions.
- The earlier XS reduction and watcher/connect micro-optimization
  investigations were already measured and closed under
  [the XS roadmap](XS-ROADMAP.md), not new work to restart.

**No next implementation was selected after `sendfile()`.**
Selection should follow demonstrated application utility and evidence,
not restart an open draft because it still appears on the roadmap.
The current authoritative categories are in
[`V1-ROADMAP.md`](V1-ROADMAP.md). This section is a dated decision
record; preserve the older optimization-phase notes below.

## Essential completion release (0.101)

Version 0.101 turns the development series into one stable public release. The
shared Timer scheduler, asynchronous Resolver and Happy Eyeballs connection
path, Signal service, established Stream deadlines, declarative TLS Streams,
Listener acceptance, and native framing catalog remain intact.

The release adds four final production surfaces. Wakeup provides a restricted
eventfd notification boundary for native producers, fork children, and cloned
ithread signalling handles. Common Stream socket policy covers local binding,
TCP and buffer configuration, interface binding, and a cached advanced hook.
Datagram adds packet-preserving UDP and Unix sockets. Process adds
`posix_spawnp`, pidfd lifecycle and signalling, decoded status, and asynchronous
standard I/O.

All high-level resources follow detached construction plus `Loop->add()` or the
equivalent `loop` constructor option. The only low-level exception is raw
`Loop->watch()`, which continues to return an opaque registration. The current
API and guarantees are documented in module POD and the focused design files;
the older sections below remain an implementation history only.

## Native Process pipe draining (after 0.105)

Priority 5 audited the remaining Linux descriptor families after Timer,
Signal, Wakeup, Resolver, Listener, Datagram, Stream, and pidfd handling were
already native. Only Process stdout and stderr still contained a repetitive
Perl `sysread` loop. A gated benchmark pre-spawns every child and starts them
only after watcher registration, isolating pipe output, callbacks, and Loop
dispatch from process construction.

The retained XS helper performs the same bounded read loop and invokes the
same cached callback once per read. It leaves EOF, error, and object lifecycle
policy in Perl. Balanced seven-repeat matrices covered stdout, stderr, and
both pipes with 1, 8, and 32 workers. Two independent 4 KiB matrices produced
paired median throughput improvements of 27.8 and 25.1 percent with lower
parent CPU in every case. Intermediate 8, 16, and 32 KiB reads improved by
19.4, 5.3, and 3.3 percent. Two default 64 KiB matrices were neutral overall:
their combined 126-pair median was 0.2 percent, inside run variance.

A saturated 32-worker run with a 1 ms recurring Timer found no fairness
regression. On the retained 0.105 measurement, the median worst Timer gap fell
from 16.881 ms to 5.225 ms with the normal 64-read cap. A longer one-read-cap
run changed it from 21.335 ms to 15.704 ms while throughput remained within
1.5 percent. The implementation therefore became the private default without
adding a public drain API or callback-batching behavior.

## Stream watcher-state profiling (0.105)

The proposed native Stream-to-Loop watcher ABI was measured before changing
ownership. The versioned `run-stream-watcher-state-bench.pl` separates direct
watcher toggles, XSState pause flags, public pause/resume, registration churn,
forced write EAGAIN, close, half-close, and TLS retry directions. It records
process CPU together with exact `epoll_ctl` calls and opt-in native timing.

The profile found unnecessary deadline work rather than an epoll ownership
problem. Established Streams marked deadline readiness even with no deadline
policy, so ordinary pause/resume and output drain rebuilt an empty candidate
set and resume read the monotonic clock. Guarding those operations by the
relevant timeout reduced median pause/resume CPU from 3.559 to 1.533
microseconds per cycle and forced-EAGAIN queue/drain CPU from 18.854 to 18.122
microseconds per cycle on the measurement host.

The remaining two `EPOLL_CTL_MOD` calls consumed about 0.48 microseconds of the
18.12-microsecond EAGAIN cycle. Initial registration's one `MOD` was below one
percent of attachment cost, and plain close/half-close had no repeating
interest churn. That evidence did not justify coupling two native extensions
through a new lifetime-sensitive ABI, so Loop remains the sole epoll owner and
Stream continues to retain an opaque registration.

## Public hierarchy simplification (0.100_025)

The 0.100_024 Watcher/IO/Connect/Listen migration exposed too many overlapping
public concepts. Version 0.100_025 removes those compatibility layers. Loop,
Stream, and Listener now express ownership directly; raw `watch()` results are
opaque native registration handles. `MyStream->connect()` is the outbound
entry point and `Linux::Event::Listener` with a configured `stream_class` is the
inbound entry point.

Both `loop => $loop` and detached construction plus `Loop->add()` are supported
for Stream and Listener. Neither adds a hot-path Perl dispatch layer. Errors,
addresses, and framing declarations also moved to their final common
`Linux::Event::Error`, `Linux::Event::Address`, and `Linux::Event::Framer::*`
namespaces. The sections below intentionally retain the names and decisions of
the release they describe.

## Unified Watcher lifecycle (0.100_024)

The public model now names every loop-owned activity a Watcher. The canonical
`Linux::Event::Loop` owns raw `Linux::Event::_Registration`, Stream, Listener, Connector,
and future composite Watchers through `add()`. Watcher is a lifecycle/type
contract only; native concrete dispatch remains direct.

Stream now represents outbound acquisition itself. `MyStream->connect()`
preserves one object identity through connect, TLS readiness, message I/O, and
close, including bounded writes issued before readiness. Listener creates and
attaches accepted Stream instances without application socket plumbing.
Connect, Listen, XSLoop, and XSWatcher remain compatibility/advanced
implementation names during the migration.

## Inbound Listen integration (0.100_020)

The earlier callback-configured listener design was replaced by
`Linux::Event::Listen` subclasses with cached `on_accept` and `on_error`
methods. Listen now owns TCP and filesystem Unix socket setup or validates an
adopted listening handle. Each accepted nonblocking, close-on-exec handle is
generic and may be handed directly to Stream, a raw watcher, or another
consumer.

A separate native extension drains `accept4`, while XSLoop continues to own
readiness and Stream continues to own established byte transport. Bounded
level-triggered batches preserve fairness; resource exhaustion pauses accept
readiness before error notification. A permanent lifecycle benchmark compares
raw accepted-handle disposal with listener-to-Stream construction.

That benchmark exposed descriptor reuse inside Connect callbacks: closing a
watched transferred handle can remove its file description from epoll before
the old watcher record is cancelled, and a new socket may immediately reuse
the number. Same-fd watcher replacement now retries `ADD` when `MOD` reports
`ENOENT`, preserving safe ownership transfer for this reuse case.

## Outbound Connect integration and watcher transfer (0.100_019)

The earlier callback-configured Linux::Event::Connect distribution was
redesigned and merged into Linux-Event. Concrete subclasses now provide cached
`on_connect` and `on_error` methods, while each request owns only target,
candidate, attempt, deadline, error, and application state. Success transfers a
generic connected filehandle and does not require Stream.

Sockets request nonblocking and close-on-exec behavior atomically. A small
Connect-native timerfd helper implements the default deadline and defers
immediate terminal outcomes until loop dispatch. Same-fd watcher replacement
was changed from DEL plus ADD to one MOD with an inert old handle, allowing a
success callback to construct Stream without a registration gap or a later
Connect cancellation removing the new watcher.

Synchronous hostname resolution and sequential candidate fallback remain
explicit initial limitations. Candidate storage is separate from attempt state
so asynchronous Resolver and Happy Eyeballs can follow without another public
API change.

## TLS SIGPIPE isolation (0.100_018)

OpenSSL's default socket BIO may use a signal-generating write after an abrupt
peer close. The TLS provider now supplies a non-owning socket BIO backed by
Linux `recv()` and `send(MSG_NOSIGNAL)`. Broken connections therefore enter
the existing typed Stream error lifecycle without installing a process-wide
signal handler or adding signal-mask syscalls to every TLS operation.

## Integrated TLS packaging (0.100_017)

The previously adjacent Linux::Event::TLS distribution moved into the main
Linux-Event release. One top-level configuration now builds XSLoop, XSStream,
and the separate TLS native extension, and one test run covers all three. TLS
uses XSStream's canonical transport ABI header rather than a duplicate copy.
This packaging change makes TLS a supported part of Linux::Event without
putting OpenSSL calls or state into XSLoop, XSStream, or ordinary plain Streams.

## Transport deadline lifecycle (0.100_016)

Cold-path provider lifecycle hooks let an adjacent transport register one
deadline watcher, disarm it after setup, reuse it for writable shutdown, and
destroy it with the Stream. This supports real stalled-handshake and stalled-
shutdown deadlines without putting timerfd or OpenSSL policy into Stream's
native parser/write engine or XSLoop.

## External transport attachment (0.100_015)

Stream published an exact-version native ABI and `transport => $provider`
construction for established descriptors. Provider lifetime is retained by
native connection state, and readiness can cross directions during handshake,
I/O, and shutdown without changing XSLoop or parser semantics. The adjacent
`Linux::Event::TLS` distribution is the first provider: it links OpenSSL and
implements secure client defaults, server mode, SNI, hostname verification,
ALPN, nonblocking handshake, and `close_notify`.

## Native transport boundary foundation (0.100_014)

Direct fd reads, writes, vectored queue drains, retry classification, and
writable shutdown moved behind one connection-local native operation contract.
The ordinary `plain` provider remains specialized: XS checks its identity and
issues the original syscall directly, avoiding a Perl callback and avoiding an
indirect function call on every plain operation.

The result model distinguishes `WANT_READ` and `WANT_WRITE`, which ordinary
EAGAIN does not need but a nonblocking TLS provider does. This release does not
publish provider attachment or add an OpenSSL dependency. The complete
handshake, verification, ALPN, buffering, shutdown, deadline, and STARTTLS
requirements are recorded in `TRANSPORT-BOUNDARY.md` before the adjacent
`Linux::Event::TLS` implementation froze the first exact-version ABI in the
following release.

## Hard pending-output limits (0.100_013)

Class transport policy gained the optional `max_pending_bytes` hard boundary.
High and low watermarks remain cooperative: false from `write()` still means
the bytes were accepted. When an unsent remainder would exceed the hard limit,
XS does not allocate its queue segment and reports a typed `output_limit` error
before Stream closes. The error retains the attempted pending count and limit.

The zero default keeps the previous unlimited behavior. The existing Stream
transport benchmark now runs otherwise identical capped and uncapped classes
to expose the cost of enabling the native check. Protocol transitions also
validate existing queued output against the target descriptor before changing
any live state.

## In-place protocol transitions (0.100_012)

The subclass descriptor became replaceable on a live connection without making
configuration per-object again. `transition_to()` retains the connection's fd,
watcher, XSState, output queue, lifecycle, application data, counters, and
unread native input while changing the Perl type and shared descriptor.

Native parser loops stop when a callback changes descriptors, then the input
driver resumes under the target parser. This specifically supports handshake
and upgrade traffic where bytes from the new protocol are already present in
the same kernel read. Raw callbacks can transfer their unconsumed suffix with
the explicit `input` option. A separate contract-1 benchmark measures live
descriptor changes without mixing them into construction results.

## Stream subclass-descriptor redesign (0.100_011)

The object-configured Stream API was replaced after capturing a versioned
constructor and retained-memory baseline. Stream behavior is now defined by
ordinary subclasses with named callbacks. Each concrete type resolves one
shared immutable XS descriptor, while connection objects retain only mutable
I/O, parser, queue, lifecycle, and application `data` state.

The same redesign removed factory-created and arbitrary custom framer objects.
Native framers are declared by exact final package name; application-specific
protocols parse raw `on_data` bytes. Current API details live in the README,
`STREAM-DESIGN.md`, and `FRAMING.md`; the older material below remains only to
document how the preceding reactor work was measured.

# Linux::Event Phase33C Bounded Callback Scope Experiment

XS-first Linux::Event loop core with Phase29-style performance defaults and experimental knobs kept out of the normal user-facing path.

## Build

```bash
perl Makefile.PL
make
make test
export PERL5LIB=$PWD/blib/lib:$PWD/blib/arch
```

## Public comparison benchmark

The local Linux::Event target is `phase33c`, which explicitly loads `Linux::Event::Loop` from `blib/lib` and `blib/arch`. This avoids accidentally benchmarking the globally installed `Linux::Event`.

The comparison harness isolates every system/client/repeat case in a fresh worker process. This prevents AnyEvent/EV default-loop state from leaking between systems and prevents `VmHWM` RSS from accumulating across earlier benchmark cases. Failed or timed-out runs retain diagnostic attempt rates in JSON, but are not assigned official ranked msg/s or MiB/s. Summary rows use successful repeats only.

The default timeout is 60 seconds and the default repeat count is 3. For stressed 20k-client runs, use `--timeout 90`.

The scale workload uses:

* TCP echo server
* one poll-based async client-driver process
* same client driver for every backend
* server-side async implementation is the only thing that changes
* configurable warmup and measured messages/client
* latency p50/p95/p99/max
* throughput msg/s and MiB/s
* correctness checks
* isolated per-case RSS and platform metadata
* echo-path counters: read callbacks, sysread/syswrite calls, EAGAINs, bytes, per-message ratios

Check dependencies first:

```bash
perl bench/run-async-comparison.pl \
  --systems phase33c,anyevent,ev,ioasync,mojo \
  --check-deps
```

Recommended scale run:

```bash
ulimit -n 100000

perl bench/run-async-comparison.pl --build \
  --systems phase33c,anyevent,ev,ioasync,mojo \
  --clients 1000,2500,5000,10000,15000,20000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --client-driver async \
  --repeats 3 \
  --timeout 90 \
  --out bench/results/comparison-scale-phase33c.html \
  --json bench/results/comparison-scale-phase33c.json
```

Open or send back:

```text
bench/results/comparison.html
bench/results/comparison.json
```

## Older focused benches

The previous Phase18F scripts are still present for quick internal checks, but the public comparison should use:

```text
bench/run-async-comparison.pl
```

## Phase20 XSLoop update

The generated comparison HTML tables are now browser-sortable. Click any column header to sort by throughput, latency, clients, RSS, backend, correctness, or hot-path counters. A small offline filter box is also included.


## Phase20 XSLoop benchmark harness

Phase20 XSLoop keeps the XS-first loop/watchers and expands the public comparison harness.

Key benchmark additions:

* sortable/filterable HTML output
* JSON output with raw runs and summary rows
* `--repeats N` for average and best-of comparison
* comma-separated `--bytes`, e.g. `64,512,4096,16384`
* server-side CPU seconds and CPU percentage
* voluntary/non-voluntary context switches
* RSS, latency percentiles/max, correctness flags
* echo-path counters and per-message ratios

Example:

```bash
perl bench/run-async-comparison.pl --build   --systems phase33b,anyevent,ev,ioasync   --clients 1,10,50,100   --warmup 100   --messages 1000   --bytes 64,512,4096,16384   --repeats 3   --out bench/results/comparison.html   --json bench/results/comparison.json
```

For a faster smoke run:

```bash
perl bench/run-async-comparison.pl --build   --systems phase20,ev   --clients 1,10   --warmup 10   --messages 100   --bytes 64   --repeats 1
```


Phase18M: fixes sortable HTML with delegated JavaScript click handling and avoids Perl interpolation-sensitive JavaScript regex literals. Keeps light per-library row coloring.


Phase18M note: HTML sorting now uses inline header onclick bindings and ES5-compatible JavaScript; row colors have stronger contrast and colored left borders.

## Phase18N harness additions

The async comparison harness now supports safer high-client-count runs:

```bash
perl bench/run-async-comparison.pl \
  --systems phase33b,anyevent,ev,ioasync \
  --clients 5000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --repeats 1 \
  --pause-between-systems 5 \
  --out bench/results/comparison-5k.html \
  --json bench/results/comparison-5k.json
```

For 10k-client runs, running each backend separately is often more reliable:

```bash
perl bench/run-async-comparison.pl --systems phase19b --clients 10000 --warmup 1 --messages 10 --bytes 64 --repeats 1 --out bench/results/phase19b-10k.html  --json bench/results/phase19b-10k.json
perl bench/run-async-comparison.pl --systems anyevent --clients 10000 --warmup 1 --messages 10 --bytes 64 --repeats 1 --out bench/results/anyevent-10k.html --json bench/results/anyevent-10k.json
perl bench/run-async-comparison.pl --systems ev       --clients 10000 --warmup 1 --messages 10 --bytes 64 --repeats 1 --out bench/results/ev-10k.html       --json bench/results/ev-10k.json
perl bench/run-async-comparison.pl --systems ioasync  --clients 10000 --warmup 1 --messages 10 --bytes 64 --repeats 1 --out bench/results/ioasync-10k.html  --json bench/results/ioasync-10k.json
```

Then merge those JSON files into one sortable/color-coded report:

```bash
perl bench/run-async-comparison.pl \
  --merge-json bench/results/phase19b-10k.json,bench/results/anyevent-10k.json,bench/results/ev-10k.json,bench/results/ioasync-10k.json \
  --out bench/results/comparison-10k.html \
  --json bench/results/comparison-10k.json
```


## Phase20 instrumentation

Phase20 is intended to be a measurement branch, not a hot-path rewrite. Normal benchmark runs leave nanosecond timing disabled so the results stay comparable with Phase19B. Cheap counters are still exposed through `$loop->stats`.

New XSLoop methods:

```perl
$loop->profile(1);   # enable nanosecond timing buckets
$loop->profile(0);   # disable timing
$loop->reset_stats;         # clear counters/timers, preserving profile flag
my $stats = $loop->stats;
```

Additional stats include:

```text
epoll_ctl_add_calls / epoll_ctl_mod_calls / epoll_ctl_del_calls
watcher_lookup_calls
dispatch_events
epoll_wait_ns
epoll_ctl_add_ns / epoll_ctl_mod_ns / epoll_ctl_del_ns
watcher_lookup_ns
dispatch_ns
```

Run a profiled XSLoop-only smoke benchmark:

```bash
perl bench/run-async-comparison.pl --build \
  --systems phase20 \
  --clients 1000,2500,5000,10000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --client-driver async \
  --xsloop-profile \
  --out bench/results/comparison-scale-phase20-profile.html \
  --json bench/results/comparison-scale-phase20-profile.json
```

For public throughput comparison, omit `--xsloop-profile`.


## Phase24

Phase24 stores the native watcher pointer directly in `epoll_event.data.ptr`, so dispatch can go straight from `epoll_wait()` to the `le_watcher_t *` without fd-indexed registry lookup in the hot path. The registry remains for public `unwatch_fd()` and lifecycle operations. Stats include `direct_watcher_events`.

## Phase29 batching/coalescing instrumentation

Phase29 keeps Phase24's direct `epoll_event.data.ptr -> le_watcher_t *` dispatch path and adds batching/coalescing diagnostics. It is intended as the measurement step before changing read-drain or event-buffer behavior.

New XSLoop methods:

```perl
my $n = $loop->event_capacity;
$loop->set_event_capacity(4096);   # optional batching experiment knob
```

New `$loop->stats` fields include:

* `event_capacity`
* `epoll_wait_empty_calls`
* `epoll_wait_full_batches`
* `epoll_wait_max_batch`
* `ready_read_events`
* `ready_write_events`
* `ready_error_events`
* `ready_multi_events`
* `read_callback_calls`
* `write_callback_calls`
* `error_callback_calls`

The benchmark target is now `phase29`:

```bash
perl bench/run-async-comparison.pl --build \
  --systems phase29,anyevent,ev,ioasync,mojo \
  --clients 1000,2500,5000,10000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --client-driver async \
  --out bench/results/comparison-scale-phase29.html \
  --json bench/results/comparison-scale-phase29.json
```

Optional event-buffer experiment:

```bash
perl bench/run-async-comparison.pl --build \
  --systems phase29 \
  --clients 1000,2500,5000,10000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --client-driver async \
  --xsloop-event-cap 4096 \
  --out bench/results/comparison-scale-phase29-cap4096.html \
  --json bench/results/comparison-scale-phase29-cap4096.json
```


## Phase29 note

Phase29 changes the default XSLoop event buffer from 1024 to 8192 based on Phase25 capacity benchmarking. The `set_event_capacity` API and `--xsloop-event-cap` benchmark override remain available for experiments.


## Phase29 notes

Phase29 is based on the Phase26 production baseline. It adds an opt-in `lean => 1` watcher mode for `callback_args => 0` callbacks. Lean watchers do not retain loop/fh/data/self accessor references because the callback closure is expected to capture all required state. The benchmark target `phase29` enables this lean mode for the echo workload.

## Phase30 watcher reclaim/free-list experiment

Phase30 is based on Phase29 and keeps the 8192 event buffer plus lean no-arg watcher mode.
It adds an opt-in watcher reclaim/free-list path intended for high-connection churn workloads:

```perl
$loop->enable_watcher_reclaim(1);
```

When enabled, `cancel()` removes the fd from epoll, clears retained SV references, and recycles the
watcher struct after the current dispatch batch. This keeps the default API behavior conservative while
letting the benchmark exercise a memory-layout/lifecycle optimization.

The benchmark target is now `phase30`:

```bash
perl bench/run-async-comparison.pl --build \
  --systems phase30,anyevent,ev,ioasync,mojo \
  --clients 1000,2500,5000,10000,15000,20000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --client-driver async \
  --out bench/results/comparison-scale-phase30.html \
  --json bench/results/comparison-scale-phase30.json
```

New stats:

- `watcher_reclaim_enabled`
- `watcher_alloc_calls`
- `watcher_reuse_calls`
- `watcher_recycle_calls`
- `watcher_destroy_calls`
- `watcher_freelist_depth`
- `watcher_freelist_max_depth`


## Phase31 watcher reuse benchmark

Phase31 keeps the Phase30 reclaim implementation experimental and adds a benchmark
that actually exercises watcher reuse:

```bash
perl bench/run-watcher-reuse-bench.pl --build \
  --systems phase29,phase31 \
  --watchers 1000,5000,10000,20000 \
  --cycles 5 \
  --out bench/results/watcher-reuse-phase31.html \
  --json bench/results/watcher-reuse-phase31.json
```

The normal async comparison target also accepts `phase31`.  It behaves like the
Phase30 reclaim path for comparison purposes.

## Phase32 API cleanup

Phase32 treats Phase29-style lean no-argument watcher dispatch as the performance baseline and keeps watcher reclaim/free-list work experimental.

Normal application code should not be expected to choose between benchmark-era knobs. The intended direction for the public API is:

```perl
my $loop = Linux::Event->new;
```

and the loop should select the best safe defaults internally.

Phase32 benchmark behavior:

- `phase33c` is the Phase33C bounded Perl callback-scope experiment and uses the tuned 8192 event buffer.
- `phase33c` keeps Phase32 HUP/RDHUP error-callback semantics while amortizing ENTER/SAVETMPS/LEAVE across bounded callback groups.
- `phase33c` uses the lean no-argument watcher storage path used by Phase29.
- `phase33c` does **not** enable watcher reclaim/free-list by default.
- `phase30` and `phase31` remain available only as experimental memory/reuse research targets.
- profiling, drain mode, event-capacity overrides, and watcher reclaim are considered internal benchmark/debug controls, not normal user-facing API choices.

Recommended public comparison command:

```bash
perl bench/run-async-comparison.pl --build \
  --systems phase33c,anyevent,ev,ioasync,mojo \
  --clients 1000,2500,5000,10000,15000,20000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --client-driver async \
  --out bench/results/comparison-scale-phase33c.html \
  --json bench/results/comparison-scale-phase33c.json
```


## Phase33C bounded callback-scope tuning

Phase33C keeps Phase32 terminal-event semantics and the Phase33B callback fast path, but bounds the number of Perl callbacks that may share one ENTER/SAVETMPS/LEAVE scope. The normal Phase33C default is 128 callbacks per scope. A limit of 0 reproduces the Phase33B whole-epoll-batch experiment.

The tuning aliases are benchmark-only controls:

```text
phase33c-1
phase33c-8
phase33c-16
phase33c-32
phase33c-64
phase33c-128
phase33c-batch
```

The loop reports `callback_scope_limit`, `callback_scope_rotations`, and `callback_scope_max_callbacks` in `stats`. The intended workflow is to tune the bounded scope on the target machine, select one safe default, and keep the tuning aliases out of the normal public API.


Phase34 persistent XS run benchmark
-----------------------------------

Phase34 keeps the Phase33C default of 128 callbacks per Perl scope and uses the
persistent XS loop for the benchmark hot path. The benchmark enters XS once via
run_for(seconds); callbacks call stop() when the final connection closes. This
removes the Perl while/run_once boundary between epoll batches while retaining a
monotonic native timeout for failed or stalled cases.


Phase34C benchmark note: `phase34c` exercises the pure persistent XS `run()` path with the catastrophic timeout enforced by the parent case supervisor. This avoids the in-worker fork/watchdog and extra epoll fd used by the Phase34B diagnostic path.

## Phase35 callback ceiling decomposition

Phase35 adds benchmark-only native echo modes to separate the remaining echo
server cost into measurable layers while keeping the real TCP workload.

- `phase35-xs`: native XS read/write echo with no Perl read callback.
- `phase35-empty`: the same native XS echo plus an empty Perl read callback.
- `phase35-perl`: the current Phase33C Perl echo callback path.

For the Phase35 experiment, B minus A estimates Perl read-callback entry cost.
C minus B estimates the additional cost of doing echo I/O and accounting in
Perl instead of XS. Terminal/error callbacks stay on the same Perl path in all
three modes so connection shutdown behavior remains comparable.

The `_bench_native_echo` watcher option is private benchmark instrumentation,
not a supported application API.

For authoritative Phase35 ceiling measurements use `bench/run-phase35-ceiling.pl`.
It pre-connects and accepts every client before the timed interval, resets XS
statistics, then releases multiple independent async client workers. This avoids
measuring connect/accept setup and prevents a single load-generator process from
becoming the ceiling before the server does.

## Strict same-work reactor ceiling comparison

`bench/run-reactor-ceiling-comparison.pl` is the fairness-focused continuation
of Phase35. It is intentionally separate from the native-echo ceiling modes.
Every ranked framework executes the same Perl `echo_read()` body and therefore
does the same server-side `sysread`, `syswrite`, buffer, and counter work.

The benchmark removes framework-specific setup and teardown from the timed
interval:

- client TCP connections are established before timing;
- the server accepts every socket directly before framework watcher setup;
- all read watchers are installed before warmup;
- warmup requests and replies finish before counters and timing are reset;
- clients keep sockets open after the last measured reply;
- EOF/RDHUP/close processing happens only after timing;
- no framework timeout watcher is active while measuring;
- the parent benchmark process supplies the catastrophic timeout.

The client protocol remains serial request/reply: each client has at most one
request outstanding. The payload, number of requests, number of clients, and
load-generator workers are identical for every system.

### Main leaderboard

The default Linux leaderboard intentionally spans several independent reactor
implementations while keeping the application body identical:

- `linuxevent`: Linux::Event XS loop on epoll;
- `ev`: public EV::io on libev/epoll;
- `anyevent-ae`: AnyEvent's fast AE::io API on the EV adaptor;
- `uv`: UV::Poll on a dedicated libuv loop;
- `ioasync-epoll`: IO::Async::Loop::Epoll using its low-level watch_io API;
- `mojo-epoll`: Mojo::Reactor::Epoll using its low-level readable-I/O API.

UV::Poll is deliberately used instead of UV::TCP because this benchmark is a
reactor comparison. Moving socket reads/buffering into libuv's TCP abstraction
would be a higher-level stream/runtime comparison rather than the same work.

Likewise, IO::Async and Mojo are driven through their low-level readiness APIs,
not IO::Async::Stream or Mojo::IOLoop::Stream. Every main row therefore enters
the same named Perl `echo_read()` function to do the measured sysread/syswrite
work.

### AnyEvent diagnostics

The AnyEvent EV adaptor has two materially different watcher-construction
paths. Its `AE::io` function is directly aliased to `EV::_ae_io` when that EV
fast path exists. The older `AnyEvent->io` method API calls public `EV::io`.
The benchmark keeps both paths available, but only the fast path is in the
default main leaderboard:

- `anyevent-ae`: normal fast `AE::io` API, driven by an AnyEvent condvar;
- `anyevent-method`: diagnostic `AnyEvent->io` method API, driven by the same condvar.

There is also an optional diagnostic system, `anyevent-ae-evrun`, which keeps
the `AE::io` watcher path but drives it directly with `EV::run`. This isolates
AnyEvent condvar loop-driving overhead from its watcher/callback path. It is a
diagnostic, not the primary AnyEvent result.

The direct EV row uses public `EV::io` and `EV::run`. EV public watcher
callbacks receive watcher and revents arguments; the shared benchmark callback
ignores framework callback arguments so the application body remains identical.

### Run

First verify dependencies:

```bash
perl bench/run-reactor-ceiling-comparison.pl --check-deps
```

Typical dependency install command:

```bash
cpanm EV AnyEvent UV IO::Async IO::Async::Loop::Epoll Mojolicious Mojo::Reactor::Epoll
```

Authoritative comparison:

```bash
ulimit -n 100000

perl bench/run-reactor-ceiling-comparison.pl --build \
  --systems linuxevent,ev,anyevent-ae,uv,ioasync-epoll,mojo-epoll \
  --clients 1000,2500,5000,10000,15000,20000 \
  --warmup 1 \
  --messages 10 \
  --bytes 64 \
  --client-workers 4 \
  --repeats 6 \
  --timeout 90 \
  --out bench/results/reactor-ceiling-comparison.html \
  --json bench/results/reactor-ceiling-comparison.json
```

The JSON records a fairness contract and a per-result work signature. Important
comparison metrics are median messages/second, p50/p95/p99 latency, server CPU
microseconds/message, RSS, context switches, reactor iterations when exposed,
read callbacks
per message, `sysread` calls per message, and `syswrite` calls per message.

`reactor_iterations` is not a portable cross-framework metric. Linux::Event
records epoll-wait/run_once activity and EV exposes its own loop-iteration
counter, while UV, IO::Async, and Mojo do not expose an equivalent total through
the APIs used here. Treat this field as an implementation-local diagnostic, not
as a leaderboard metric.

For a fair reactor conclusion, compare only rows where the work signature and
exact byte/syscall correctness checks pass. Do not compare Phase35 native-echo
modes against EV/AnyEvent Perl echo as if they were the same abstraction level.

## Balanced competitor execution order

The competitor ceiling harness runs one client-count/repeat block at a time and
rotates the system order deterministically. With the default six systems and
six repeats, each system appears in each execution position once per client
count. This prevents long-run CPU-frequency, thermal, and scheduler drift from
being systematically assigned to one framework simply because all of its cases
ran earlier or later than another framework's cases. If diagnostics are added,
use a repeat count that is a multiple of the selected system count for perfect
position balance; the harness warns when it is not.

Each JSON row records `execution_order_mode`, `execution_order_position`,
`execution_order_width`, and `execution_block`.

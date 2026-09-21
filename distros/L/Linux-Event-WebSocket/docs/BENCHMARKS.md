# Linux::Event::WebSocket Benchmarks

These measurements guide implementation decisions. They are not published as
hardware-independent performance claims.

## Current native-engine decision

The production integration now uses the locally patched vendored bq core
through XS. This decision followed same-run experiments against the previous
Perl engine and a wslay prototype.

Representative optimized-bq results included:

| workload | previous main | wslay | optimized bq |
| --- | ---: | ---: | ---: |
| text 64 B, 1 client | ~28k/s | ~68k/s | ~95k/s |
| text 1 KiB, 1 client | ~26k/s | ~44k/s | ~84k/s |
| text 16 KiB, 1 client | ~9.9k/s | ~5.2k/s | ~25k/s |
| text 64 B, 100 clients | ~22k/s | ~53k/s | ~69k/s |

One-way realistic mixed JSON/emoji traffic also favored bq. A corrected
client-to-server sample measured about 82.5k/s at 64 B, 60.1k/s at 1 KiB, and
11.85k/s at 16 KiB, versus about 63.8k/18.0k/1.46k for wslay and
34.7k/9.95k/0.81k for the previous main implementation.

A pub/sub fan-out benchmark, where one producer message was broadcast and
actually received by every subscriber before the next cycle, measured
approximately 61.5k aggregate deliveries/s at 256 B / 100 subscribers,
56.6k/s at 1 KiB / 100, and 20.6k/s at 16 KiB / 100. The same cases were about
46.9k/27.0k/2.7k for wslay and 35.6k/16.9k/1.49k for previous main.

These are development-runner measurements, not universal performance claims.
Their role is architectural: the gains were large, repeated across realistic
workloads, and survived the full correctness gates.

## Raw native-input boundary

Linux::Event 0.116 adds a raw native-consumer ABI that exposes the borrowed
ordered-byte input window before core materializes the read as a Perl SV.
`bench/raw-input-boundary.pl` was used to compare that path against the
previous `on_data -> _Engine::feed` receive boundary while keeping the same
bq protocol engine and the same `_Engine` application delivery.

The workload is one-way masked client traffic rather than echo. Text cases use
valid UTF-8 JSON-like payloads containing non-ASCII data; binary cases use byte
payloads. The producer writes continuously through a nonblocking raw watcher,
the benchmark warms the path before measurement, and the message callback uses
a wall-clock cutoff.

A same-run Perl 5.44 hosted-runner sample after direct Engine dispatch measured:

| workload | current Perl input | raw ABI | raw delta |
| --- | ---: | ---: | ---: |
| text 64 B | 402,039 msg/s | 407,898 msg/s | +1.5% |
| binary 64 B | 447,075 msg/s | 455,547 msg/s | +1.9% |
| text 1 KiB | 286,230 msg/s | 322,621 msg/s | +12.7% |
| binary 1 KiB | 327,759 msg/s | 384,722 msg/s | +17.4% |
| text 16 KiB | 48,097 msg/s | 67,860 msg/s | +41.1% |
| binary 16 KiB | 66,444 msg/s | 108,853 msg/s | +63.8% |

The size-dependent result is consistent with eliminating the Perl read-scalar
copy: the benefit is small at 64 B, material by 1 KiB, and large at 16 KiB.

An earlier raw adapter revision appeared about 17-18% slower than the current
path at 64 B. That was not a core-ABI limitation. The adapter sent every
completed message through a Perl method on the Stream, which then called
`_Engine::_bq_event`, adding one unnecessary Perl dispatch per message. The
final provider retains the actual Engine once and invokes `_bq_event`
directly from XS. Removing that wrapper changed 64-byte traffic from a material
loss to a small win while increasing the gains at larger payloads.

The raw provider also keeps the Engine `in_feed` guard in XS so application
sends from receive callbacks preserve the existing non-reentrant behavior.
Regression coverage includes split input, text/binary messages, Ping/Pong, and
Close.

The raw provider is now the established receive path used by the public client
and server APIs. The HTTP opening exchange uses a temporary native byte bridge,
then Linux::Event replaces that provider with the bq WebSocket consumer at the
101 protocol transition.

### Public application A/B

A same-run public-API comparison built `feature/bq-native-engine` as the
pre-raw baseline and the raw-ABI integration from the current branch on the
same GitHub runner. The workload used 20 public WebSocket clients with a window
of four in-flight requests per connection. Clients sent JSON-like text
messages; the server performed a small application-level check and returned a
fixed JSON acknowledgement. HTTP Upgrade time was excluded.

Five alternating baseline/raw samples were collected for each payload size.
Median results were:

| request payload | pre-raw baseline | raw ABI public path | delta |
| --- | ---: | ---: | ---: |
| 256 B | 52,719 txn/s | 59,279 txn/s | +12.4% |
| 1 KiB | 49,200 txn/s | 55,760 txn/s | +13.3% |
| 16 KiB | 24,739 txn/s | 28,380 txn/s | +14.7% |

Median ingress throughput moved from 12.87 to 14.47 MiB/s at 256 B, 48.05 to
54.45 MiB/s at 1 KiB, and 386.54 to 443.44 MiB/s at 16 KiB.

This workload is deliberately not an echo server: request payload and response
payload differ, application logic runs on the server, and throughput is counted
as completed request/ack transactions. The result confirms that the raw-input
boundary survives integration through the real HTTP Upgrade and public
WebSocket APIs.

## High-concurrency application scaling

A focused application-style comparison was added after the raw native-consumer
integration. The workload uses JSON-like text requests, a fixed JSON
acknowledgement, one outstanding request per connection, and 64-byte or
256-byte requests. Five samples were taken at 20, 100, 500, and 1000
connections on the same hosted runner. Linux::Event::WebSocket was built
against Linux::Event 0.116 from current `main`.

Median 64-byte results were:

| clients | Linux::Event | Mojolicious | Node ws | Gorilla |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 26.7k txn/s | 8.3k | 40.2k | 33.0k |
| 100 | 27.4k txn/s | 8.4k | 40.4k | 32.2k |
| 500 | 23.0k txn/s | 6.2k | 38.1k | 27.4k |
| 1000 | 23.8k txn/s | 6.1k | 36.0k | 26.9k |

Median 256-byte results were:

| clients | Linux::Event | Mojolicious | Node ws | Gorilla |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 26.2k txn/s | 8.1k | 39.5k | 32.2k |
| 100 | 25.6k txn/s | 7.8k | 38.1k | 31.6k |
| 500 | 21.3k txn/s | 6.1k | 36.4k | 27.2k |
| 1000 | 22.8k txn/s | 6.3k | 35.1k | 25.6k |

The Linux::Event result does not show a concurrency collapse. Throughput falls
moderately after 100 connections and remains stable through 1000. The remaining
gap to Node/Gorilla in this workload is therefore not explained by a simple
high-connection-count failure.

A follow-up Linux::Event-only window-depth sweep separated protocol throughput
from one-request-at-a-time round-trip latency. It used 64-byte application
requests and the same 20/100/500/1000 connection counts. Median results were:

| clients | window 1 | window 4 | window 16 |
| ---: | ---: | ---: | ---: |
| 20 | 26.9k txn/s | 54.1k | 59.2k |
| 100 | 27.4k txn/s | 52.9k | 56.5k |
| 500 | 23.7k txn/s | 52.4k | 56.9k |
| 1000 | 23.3k txn/s | 50.3k | 56.6k |

The large jump from window 1 to window 4, followed by a much smaller gain from
4 to 16, is strong evidence that the one-outstanding-request case is dominated
by per-roundtrip scheduling/dispatch latency rather than RFC6455 parsing
throughput. At window 16 the server sustains roughly 56-59k transactions/s
across 20 through 1000 clients.

The diagnostic scripts are:

- `bench/compare/run-high-concurrency-small-text.sh`;
- `bench/compare/run-linux-event-window-depth.sh`.

The manual `WebSocket high-concurrency comparison` GitHub Actions workflow
runs both diagnostics without lengthening normal CI.

## Send-path turnaround isolation

A follow-up diagnostic isolated the response path after the high-concurrency
window-depth result. The server handled the same 64-byte application request at
1000 concurrent connections using five response implementations:

- the public `send_text()` API;
- direct `_Engine->send_text()`;
- direct native bq queueing with the normal end-of-consumer deferred flush;
- native bq queueing followed by an immediate flush/write from inside the
  message callback;
- a preframed WebSocket acknowledgement written directly through
  `Stream->write()`.

Three samples were taken at window 1 and window 4. Median results were:

| response path | window 1 | window 4 |
| --- | ---: | ---: |
| public send_text | 23.1k txn/s | 47.5k txn/s |
| direct Engine | 23.3k | 49.5k |
| native queue, deferred flush | 24.4k | 49.6k |
| native queue, immediate flush/write | 23.1k | 38.0k |
| preframed Stream write | 24.2k | 39.9k |

The result rules out WebSocket frame construction and the public
`Connection::send_text -> _Engine::send_text` method chain as the primary
source of the window-1 gap. Bypassing both improves the one-outstanding-request
case by only about 5%.

More importantly, forcing an immediate write from inside each message callback
reduces window-4 throughput by roughly 20%. The existing raw-consumer design is
therefore doing useful work: all messages already available in one native input
delivery queue their responses into bq, and the consumer flushes the aggregate
wire output once after callback delivery. That coalescing should be preserved.

Current Linux::Event `Stream->write()` already invokes native `_write()`
immediately when the socket is writable. Diagnostic core counters showed no
write EAGAINs and no retained pending output in this workload. The large
window-1 versus window-4 difference is therefore primarily fixed per-turn
overhead: native read/drain, raw-consumer entry, C-to-Perl application callback,
WebSocket output production, and one native write submission for each
one-at-a-time transaction. Windowed traffic amortizes those fixed costs across
several messages and one deferred output flush.

A separate experimental raw-write bridge (PR #17) showed that bypassing the
public Perl `Stream->write()` wrapper after the deferred bq flush can improve
the 1000-client window-1 median by about 13%, while retaining a small gain at
window 4. That experiment deliberately reaches into private Linux::Event Stream
state and is not suitable as a production WebSocket dependency.

The architectural follow-up is therefore a generic Linux::Event native-consumer
host output operation: a raw consumer should be able to submit an already-built
wire buffer directly to the owning Stream's native output machinery while
preserving normal buffering, backpressure, write-interest, error, TLS, and
lifecycle semantics. Such a facility belongs in Linux::Event core rather than
as a WebSocket-specific private-state bypass.

The diagnostic is retained as
`bench/compare/run-send-path-turnaround.sh` and the manual
`WebSocket send-path turnaround diagnostic` workflow.

## Method

Repository author benchmarks live under `bench/`.

- `protocol.pl` isolates framing, masking, parsing, and UTF-8 validation.
- `raw-input-boundary.pl` compares the old Perl input boundary with the
  Linux::Event raw native-consumer ABI using the same bq/Engine message path.
- `application.pl` measures public request/ack application traffic with
  JSON-like text requests and fixed acknowledgements.
- `echo.pl` measures steady-state round trips through the public WebSocket
  client and server APIs.
- HTTP Upgrade time is excluded from steady-state measurements.
- GitHub-hosted runners are useful for regression samples, but their absolute
  throughput varies between runs.

The first baseline was taken on Perl 5.44 on an Ubuntu GitHub runner using an
AMD EPYC 7763-class host.

## Historical Bottleneck 1: client mask randomness

The original pure-Perl implementation opened, read, and closed `/dev/urandom`
for every client frame.

A same-run microbenchmark measured approximately:

| operation | original | persistent fd |
| --- | ---: | ---: |
| four random bytes | 129k/s | 896k/s |
| 64-byte masked frame encode | 90k/s | 256k/s |
| 1 KiB masked frame encode | 86k/s | 239k/s |
| 16 KiB masked frame encode | 43k/s | 70k/s |

The pure-Perl implementation was improved by keeping one lazy, close-on-exec
`/dev/urandom` descriptor. The current native engine supersedes that path and
uses Linux `getrandom(2)` for client mask keys.

## Historical Bottleneck 2: UTF-8 validation

The first RFC 3629 validator walked every byte in Perl. That was correct but
became the dominant cost for text messages.

Representative original validation rates were approximately:

| ASCII payload | original Perl byte loop |
| --- | ---: |
| 64 bytes | 151k/s |
| 1 KiB | 10k/s |
| 16 KiB | 655/s |

A full RFC regular expression did not scale well enough. The pure-Perl path was
improved with an ASCII fast path plus C-backed decoding.

The current native engine supersedes that implementation. Inbound and outbound
text now use Perl's C UTF-8 API directly from XS with the RFC 3629 boundary.
That avoids a Perl-level validation/copy pass while preserving rejection of
overlong encodings, surrogates, Perl-extended UTF-8, and values above
U+10FFFF. Unicode noncharacters remain permitted.

## End-to-end effect

Hosted-runner results vary, so these are directional samples rather than a
strict hardware comparison.

| public echo case | initial baseline | after Perl optimizations |
| --- | ---: | ---: |
| binary, 64 B, 1 client | 16.0k msg/s | 21.0k msg/s |
| binary, 1 KiB, 1 client | 13.8k msg/s | 17.5k msg/s |
| binary, 16 KiB, 1 client | 7.4k msg/s | 8.0k msg/s |
| text, 64 B, 1 client | 9.4k msg/s | 16.9k msg/s |
| text, 1 KiB, 1 client | 1.4k msg/s | 14.7k msg/s |
| text, 16 KiB, 1 client | 97 msg/s | 5.7k msg/s |
| binary, 64 B, 10 clients | 12.8k msg/s | 17.2k msg/s |
| binary, 64 B, 100 clients | 13.0k msg/s | 16.3k msg/s |

The random-source optimization also produced a separate hosted-runner sample of
roughly 31k msg/s for 64-byte binary round trips, illustrating why absolute
GitHub-runner values should not be compared too literally across runs.

## Native-code conclusion

The early pure-Perl optimizations were useful and remain documented below, but
later end-to-end measurements changed the conclusion. The vendored bq engine
with a thin XS adapter materially improves the real protocol path, especially
for medium/large text, Unicode-heavy traffic, concurrency, and fan-out.

The native code therefore belongs in Linux::Event::WebSocket. Linux::Event core
remains unchanged because this optimization is protocol-specific.

## Cross-implementation comparison

A repository-only comparison harness under `bench/compare/` runs minimal echo
servers and clients for:

- Linux::Event::WebSocket;
- Mojolicious 9.49;
- Node.js `ws` 8.21.3 with `bufferutil` 4.1.0;
- Go `gorilla/websocket` 1.5.3.

The server comparison uses one common Node `ws` load generator. The client
comparison uses one common Node `ws` echo server. Compression is disabled.
On runners with at least two CPUs, the implementation under test is pinned to
CPU 0 and the driver/peer to CPU 1. Go is constrained to `GOMAXPROCS=1`.
Each case warms up for 0.5 seconds and measures for 1.5 seconds after the
WebSocket handshake.

A post-integration same-run server comparison from draft PR #9 measured:

| case | Linux::Event | Mojolicious | Node ws | Gorilla |
| --- | ---: | ---: | ---: | ---: |
| binary 64 B, 1 conn | 147.7k | 43.9k | 168.1k | 192.0k |
| binary 1 KiB, 1 conn | 132.2k | 40.1k | 154.1k | 165.3k |
| binary 16 KiB, 1 conn | 39.2k | 19.0k | 72.9k | 45.1k |
| binary 64 B, 100 conn | 123.4k | 37.2k | 160.8k | 166.0k |
| text 64 B, 1 conn | 156.0k | 39.9k | 158.5k | 174.2k |
| text 1 KiB, 1 conn | 138.6k | 35.2k | 142.8k | 143.6k |
| text 16 KiB, 1 conn | 38.7k | 14.6k | 39.1k | 41.3k |
| text 64 B, 100 conn | 125.1k | 33.5k | 146.3k | 146.2k |

The mirror client comparison on the same runner measured:

| case | Linux::Event | Mojolicious | Node ws | Gorilla |
| --- | ---: | ---: | ---: | ---: |
| binary 64 B, 1 conn | 133.8k | 47.9k | 170.6k | 184.4k |
| binary 1 KiB, 1 conn | 126.5k | 45.1k | 157.8k | 157.0k |
| binary 16 KiB, 1 conn | 40.2k | 25.4k | 72.6k | 25.9k |
| binary 64 B, 100 conn | 113.0k | 43.6k | 159.9k | 159.8k |
| text 64 B, 1 conn | 138.0k | 45.5k | 159.4k | 179.0k |
| text 1 KiB, 1 conn | 126.1k | 41.5k | 141.4k | 155.6k |
| text 16 KiB, 1 conn | 46.1k | 22.7k | 34.9k | 25.5k |
| text 64 B, 100 conn | 114.6k | 40.5k | 145.9k | 158.0k |

These are hosted-runner measurements and should not be interpreted as universal
rankings. They do show that the integrated native path is no longer in the same
performance regime as the earlier Perl implementation: server text throughput
is close to Node/Gorilla in the tested 64 B through 16 KiB single-connection
cases, and Linux::Event's 16 KiB text client exceeds both comparison clients in
this run.

## Timer-fairness observation

The first version of the external client comparison used Linux::Event timers to
end each measurement interval. Under sustained external echo traffic, nominal
1.5-second timers were delayed by tens of seconds. A wall-clock cutoff checked
from the message path produced stable 1.5-second measurements.

That behavior is not attributed to Linux::Event::WebSocket itself. It is a
separate Linux::Event core scheduling/fairness follow-up and should be
investigated in the core repository only with explicit authorization.

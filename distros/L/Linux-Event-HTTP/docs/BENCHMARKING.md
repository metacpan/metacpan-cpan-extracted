# Linux::Event::HTTP benchmarking

HTTP/1 throughput was compared with the former implementation before the
0.004 release. The measured gap is documented, not a fixed release target.
Never compare results from different machines as a direct A/B result.

## Rebuilt end-to-end benchmark

After `perl Makefile.PL && make`, run:

```sh
perl -Mblib bench/run-unblock-end-to-end.pl \
    --requests 10000 --warmup 1000 --connections 100 \
    --pipeline 1 --response-bytes 32 --repeats 2
```

The same harness accepts `--no-native-input` to compare the Perl path.
For historical performance, compare with the original 0.003 source (commit
`c0bf714e0f08f9031684e2eb4fd70dea3c68449f`) on the same runner,
using its `bench/run-http-end-to-end.pl`.
A manually dispatched CI run can perform a legacy/rebuild/rebuild/legacy
sequence. Ordinary push CI focuses on correctness and packaging.

The new client benchmark is `bench/run-rebuild-client.pl`.
`bench/run-unblock-engine.pl` isolates the protocol engine without
TCP socket costs; `bench/run-unblock-retention.pl` examines retained
memory during server/client request workloads.

## Independent Perl HTTP server comparison

For a peer baseline, the development workflow
`.github/workflows/http1-peer-benchmark.yml` uses the unchanged shared
client from [Benchmark::Web](https://github.com/haxmeister/perl-Benchmark-Web)
(revision `ceb8b2f9c4cd0764441844dd91dacc1240ebc4c7`).
It compares the rebuilt Server's normal public API (a fresh Uniform
response for each request) against the original Linux::Event::HTTP,
Feersum, Hyperman and Mojolicious. No Unblock engines were modified.

Validated 2026-10-25 on one GitHub-hosted Ubuntu runner:
https://github.com/haxmeister/perl-Linux-Event-HTTP/actions/runs/40211468264

All servers used one process and one application execution slot,
100 persistent HTTP/1.1 loopback connections, pipeline depth 1,
a 32-byte HTTP 200 response body, a shared raw Perl client, and
rotated target order. GET: 20,000 measured, 2,000 warmup, 5 repeats;
POST: 4,096-byte complete body, 10,000 measured, 1,000 warmup,
3 repeats. The table shows the median requests per second:

| Server | GET /bench | POST /bench, 4 KiB |
| --- | ---: | ---: |
| Hyperman | 111,289 | 67,543 |
| Feersum | 108,622 | 99,643 |
| Original Linux::Event::HTTP | 40,413 | 34,617 |
| Linux::Event::HTTP (Unblock rebuild) | 9,666 | 7,991 |
| Mojolicious | 2,483 | 2,334 |

This is a comparative protocol-stack workload, not identical
application-level processing across frameworks. The rebuild passes
canonical Uniform messages through a generic transaction lifecycle;
other adapters use their normal documented APIs. The result identifies
a meaningful throughput gap against the faster Perl servers but does
not, on its own, establish a defect in the Unblock::HTTP1 engine or
justify rewriting the shared architecture.

These absolute numbers apply to that hosted runner only. Do not
treat them as deployment capacity or cross-machine rankings. The
complete JSON records and latency percentiles are preserved in the
GitHub Actions artifact `stage-b-http1-perl-peers`. Historical
`bench/results/` JSON files are retained in Git but deliberately
excluded from the CPAN source archive. The benchmark-only adapter
also remains in Git, not in the shipped distribution.

## Cost-boundary diagnostics

```sh
perl -Mblib bench/run-unblock-cost-breakdown.pl \
    --iterations 12000 --rounds 3
```

This measures canonical Uniform::HTTP::Response construction, wire-plan
work, direct Unblock::HTTP1 and the upper Unblock facade under matched
conditions. The temporary
`--diagnostic-prebuilt-response` option of the end-to-end harness
uses a single frozen canonical Response **only to bound constructor cost**.
It is not a production caching recommendation; engines must not reuse or
mutate application responses behind callers.

Recorded evidence in Git (not shipped in the source archive):
`bench/results/unblock-stage-b/20261025-cost-boundary.json`
and `bench/results/unblock-stage-b/20261025-bodyless.json`,
plus the active status and handoff documents.
In the paired runs so far, the upper Unblock facade added no meaningful
per-request penalty versus direct HTTP1. Native input outperformed the
Perl bridge, but the rebuilt real-socket throughput remained well below
the legacy baseline, which is a measured trade-off rather than an unresolved release blocker.

HTTP/2 h2spec, HTTP/3 QUIC/TLS, WebSocket and generic CONNECT regressions
are protocol correctness checks, independent of HTTP/1 throughput.

## Published-stack validation and historical reproduction

Current CI installs Unblock::HTTP 0.03, HTTP1 0.13, HTTP2 0.13 and HTTP3
0.14 from CPAN. Historical Linux::Event::HTTP comparisons use the frozen original
0.003 source at c0bf714e0f08f9031684e2eb4fd70dea3c68449f.

The original development-stack workflows and exact dependency pins are
preserved at root revision 476f2e84bfcff2d326c46a75a8a9b690c0c3cca4.
Use that revision's workflow/dependency set to reproduce the old HTTP1
engine before/after experiment (06a0f5d7c0509ad0deaebe4a8269c03fbe07ea14
versus 4d19f59196481ae4460207c5b22c5125fdbfe186, upper layer
e9efa51ee0110227945628f3f85a3feedba90558). Do not prepend old engine
Perl sources to the published 0.13 XS installation: their version checks
correctly reject that mixed installation. Current correctness CI and
current benchmarks use the complete published stack instead.

## Server-only and independent native CPU profiles

`--nytprof` profiles only the server event loop, excluding the load generator
and setup. It needs the optional developer tool Devel::NYTProf (tested with
6.16). Run ordinary benchmarks without profiling for throughput; profiler
instrumentation substantially changes absolute costs and relative weights.
On Linux, `clock=2` selects process CPU time rather than time waiting in epoll.
The denominator below includes the 1,000 warmup requests.

```sh
NYTPROF=file=/tmp/socket.nytprof:addpid=1:start=no:stmts=0:calls=2:clock=2 \
  perl -Mblib -d:NYTProf bench/run-unblock-end-to-end.pl \
  --nytprof --requests 10000 --warmup 1000 --repeats 1
perl tools/http1-profile-summary.pl /tmp/socket.nytprof.CHILD_PID 11000

NYTPROF=file=/tmp/engine.nytprof:start=no:stmts=0:calls=2:clock=2 \
  perl -d:NYTProf bench/run-unblock-engine.pl \
  --case engine_input_and_response --native-input --nytprof --requests 10000
perl tools/http1-profile-summary.pl /tmp/engine.nytprof 11000
```

The independent engine case uses HTTP1 0.13's own diagnostic BorrowedDriver,
without any Linux::Event module or socket. The helper is private upstream
benchmark machinery, not an application API or a production dependency.
Omit `--native-input` for ordinary portable input. `--case` prevents separate
constructor/control benchmarks from contaminating the engine profile.
The summary reports exclusive subroutine time and calls per request;
inclusive times in JSON overlap and must not be added. C work without its
own Perl frame can be charged to its enclosing call, so namespace shares
are attribution evidence, not an exact limit on possible optimization.

Detailed historical profiler data is retained in Git. These diagnostics
are not required for application use.

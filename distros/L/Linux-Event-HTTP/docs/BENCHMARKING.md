# Linux::Event::HTTP benchmarking

The distribution keeps parser microbenchmarks and full HTTP transaction
benchmarks separate. The parser benchmark answers questions about pico and the
native Request representation. The end-to-end harness measures the combined
cost of TCP accept/read/write, HTTP parsing, Request/Response message lifecycle,
Transaction execution, application callback dispatch, response serialization,
persistence, and the client-visible round trip.

## End-to-end harness

Run from a built checkout:

```sh
perl -Mblib bench/run-http-end-to-end.pl
```

The harness forks the Linux::Event HTTP server into a separate process and runs
the load generator in the parent. This avoids putting the client and server on
the same event loop or in the same Perl interpreter.

Defaults:

```text
measured requests:    20000
warmup requests:       2000
connections:            100
pipeline depth:            1
request body bytes:         0
response body bytes:       32
repeats:                    5
```

Each repeat starts a fresh server process. Connections stay persistent through
warmup and measurement. The server returns a fixed scalar response with
Content-Length so the default result measures the ordinary HTTP/1.1 request and
`Response->body` callback-return path. Transaction output lifecycle and the
private eligible scalar fast path remain part of the measured server stack;
incremental response production and chunked response framing are not part of the
default workload.

Useful variations:

```sh
# Higher concurrency
perl -Mblib bench/run-http-end-to-end.pl \
  --requests=100000 --warmup=10000 --connections=500

# HTTP/1.1 pipelining
perl -Mblib bench/run-http-end-to-end.pl \
  --requests=100000 --connections=100 --pipeline=16

# Request-body path
perl -Mblib bench/run-http-end-to-end.pl \
  --requests=50000 --connections=100 --request-body-bytes=4096

# Larger scalar response
perl -Mblib bench/run-http-end-to-end.pl \
  --requests=50000 --connections=100 --response-bytes=65536
```

The text result reports requests/second, p50/p95/p99/max client-visible latency,
and server process CPU microseconds per request. `--json=PATH` writes the full
configuration, environment, per-repeat records, medians, and Linux::Event loop
statistics.

## Cross-server comparison harness

A second harness drives multiple HTTP servers with the same raw Perl client code
and the same wire workload:

```sh
perl -Mblib bench/run-http-comparison.pl
```

The primary comparison set is:

- Linux::Event::HTTP;
- Feersum using its native HTTP interface;
- Mojolicious using Mojo::Server::Daemon;
- Node.js built-in `http` server;
- Go `net/http`;
- Python aiohttp.

Twiggy/AnyEvent remains available with `--servers=twiggy`, but is not in the
primary set because current Twiggy closes the long-lived benchmark connections
before the requested keep-alive workload completes.

All primary comparison servers run as one process with one application execution
slot. The Go adapter sets `GOMAXPROCS=1`; the Go runtime may still create helper
OS threads, so this constraint means one slot for executing Go code rather than
literally one runtime thread. The Go server is compiled once before measurement
and the resulting binary is executed directly for every repeat.

The harness starts a fresh server for each repeat, uses persistent loopback TCP
connections, rotates server order between repeats, and applies the same
connection count, pipeline depth, request body, response body, warmup, response
parser, and latency measurement to every server.

That contract is intentional. A prefork server such as Starman should be
compared separately because multiple worker processes answer a different
capacity-scaling question.

Competitors are optional locally. Missing runtimes or modules are skipped unless
`--strict` is supplied. A complete primary setup needs Mojolicious and Feersum
in Perl, Node.js, a Go toolchain, and Python aiohttp. Twiggy is needed only when
it is selected explicitly.

Examples:

```sh
# Default six-way comparison
perl -Mblib bench/run-http-comparison.pl \
  --requests=50000 --warmup=5000 --connections=100 --repeats=5

# Compare the primary Perl servers
perl -Mblib bench/run-http-comparison.pl \
  --servers=linuxevent,feersum,mojo \
  --requests=50000 --connections=100 --repeats=5

# Request-body workload
perl -Mblib bench/run-http-comparison.pl \
  --request-body-bytes=4096 --response-bytes=32

# Pipelining workload
perl -Mblib bench/run-http-comparison.pl \
  --pipeline=16

# Machine-readable report
perl -Mblib bench/run-http-comparison.pl \
  --json=bench/results/http-comparison.json
```

Comparison output reports per-repeat and median requests/second plus
p50/p95/p99/max client-visible latency. Runtime and framework versions are
included in JSON output when available.

The comparison is a protocol-stack comparison, not an attempt to make each
framework perform an identical amount of application-layer work. Each adapter
uses the smallest normal server API that still receives the complete request
body before producing the same fixed Content-Length response payload.

## Profiling

Normal benchmark runs leave Linux::Event native nanosecond timing disabled so
measurement overhead does not contaminate the throughput baseline. Cheap loop
counters are still recorded.

Use a separate profiling run when event-loop timing is needed:

```sh
perl -Mblib bench/run-http-end-to-end.pl \
  --requests=50000 --connections=100 --profile \
  --json=bench/results/http-profile.json
```

`--profile` enables `$loop->profile(1)` in the server process. Compare profiling
runs only with other profiling runs.

## CI smoke mode

```sh
perl -Mblib bench/run-http-end-to-end.pl --smoke
perl -Mblib bench/run-http-comparison.pl --smoke
```

Smoke mode uses a tiny workload and exists only to verify that the harness can
start servers, maintain persistent connections, pipeline requests, parse
responses, and collect latency. GitHub-hosted runner throughput must not be used
as a release performance claim.

## Measurement discipline

For publishable numbers:

- use a stable local machine or dedicated runner;
- record CPU model, kernel, runtime and framework versions;
- pin or otherwise control CPU placement when comparing small differences;
- run multiple repeats and report medians;
- keep request/response sizes, connection count, and pipeline depth identical;
- compare one-process servers with one-process servers unless worker scaling is
  the subject of the test;
- compare non-profiled runs with non-profiled runs;
- avoid running unrelated CPU- or network-heavy work at the same time;
- retain the JSON report with the benchmark conclusion.

A single parser microbenchmark number is not a server throughput number, and a
single end-to-end throughput number does not identify where CPU time is spent.
Use the parser benchmark, the end-to-end harness, the comparison harness, and
Linux::Event profiling as separate views of the stack.

# Linux::Event::HTTP

Linux::Event::HTTP integrates Linux::Event's native sockets, TLS and timers
with the event-loop-neutral Unblock::HTTP protocol engines. Server and Client
expose Unblock transactions and Uniform messages. There is no compatibility
layer for the previous Linux::Event::HTTP API.

The distribution provides HTTP/1 servers and clients over TCP and TLS,
real Unblock transactions and Uniform messages, bounded buffering, streaming
reception/responses, pooling, cancellation, timers and native borrowed input.
Queued streaming uploads and graceful HTTP/1 service shutdown are implemented.
Optional HTTP/2 over TLS uses ALPN, multiplexing, flow control and GOAWAY.
HTTP/3 Client and combined TCP/UDP Server integration is verified
with real QUIC/TLS loopback, timeout, cancellation, congestion and
multi-connection tests. HTTP/1 Upgrade and HTTP/2/3 WebSocket and generic
CONNECT handoff are verified. HTTP/2 strict h2spec conformance passes with
Unblock::HTTP2 0.13 or newer. HTTP/1 throughput was measured against the
previous implementation; its trade-offs are documented, not an open
requirement for identical requests-per-second performance.

## Server

```perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::HTTP::Server;

my $loop = Linux::Event::Loop->new;
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    port => 8080,
    on_request => sub ($tx, $request) {
        $tx->respond(status => 200, body => "Hello\n");
    },
);
$loop->run;
```

`on_headers($tx, $request)` runs at headers. `on_request` runs once after the
whole body and trailers complete successfully. To stream an incoming body,
register `$tx->on_data(sub ($tx, $bytes) { ... })` during `on_headers`.
Otherwise Unblock buffers up to 1 MiB by default. Set
`http1 => { max_buffered_body_bytes => $bytes }` to change that bound.

Stream a response using `$tx->respond(status => 200, stream_body => 1,
on_drain => sub ($tx) { ... })`, followed by `write` and `end`. A false
`write` return means the chunk was accepted but the producer must pause until
`on_drain`; never resend that chunk.

`loop`, `listener`, `host`, `port`, `connection_count`, `pause`, `resume` and
`close` expose service controls. `close` closes TCP admission; with HTTP/3 enabled it also starts QUIC
GOAWAY draining. It does not immediately discard admitted H3 streams.
`shutdown(grace => 30, on_complete => sub ($server) { ... })` stops accepting,
completes admitted requests and responses, and closes any remaining owned
sockets after the grace deadline. Completion runs once after all owned
connections and transactions finish. It may run synchronously if idle.

## Client

```perl
use Linux::Event::HTTP::Client;

my $client = Linux::Event::HTTP::Client->new(loop => $loop);
my $op = $client->get('https://example.com/',
    timeout => 15,
    on_response => sub ($tx, $response) {
        say $response->status;
        say $response->body;
    },
    on_error => sub ($object, $error, @protocol_details) { warn "$error\n" },
);
$loop->run;
```

Without `on_data`, `on_response` receives the complete bounded response.
Supplying `on_data` selects streaming automatically: headers trigger
`on_response`, chunks trigger `on_data($tx, $bytes)`, and successful body
completion triggers `on_end($tx)`. `on_finish` runs on terminal cleanup.

The return value is the real Unblock operation. It supports `cancel`, `state`,
`error`, `is_terminal` and `transaction`; the transaction appears after
admission. Timeouts include queueing, connection establishment and reception.

Unblock owns the pools and their limits. `pool_stats`, `pending_count`,
`network_changed` and `shutdown` retain Unblock's semantics. Client shutdown
cancels queued work, lets active work finish and retires connections.
Stream an upload with `stream_body => 1` and
`on_transaction => sub ($tx) { $tx->write(...); $tx->end }`. The callback gets
the real transaction when queued work is admitted. It can run synchronously
on an available connection; use its argument rather than an operation
variable that may not yet have been assigned. There is no second body queue.

HTTPS verifies certificates and the original hostname by default. Use
`tls => { ca_file => $path }` for a private trust root. The Client owns TLS
hostname and ALPN selection. Server TLS options are passed as
`tls => { cert_file => $cert, key_file => $key }`.

## HTTP/3

Install `Net::QUIC >= 0.06` and `Unblock::HTTP3 >= 0.14`, then enable
`http3 => 1`. A strict Client request can use `http_version => '3'`.
A client may pass `quic => { ca_file => $path }` for a private CA and
uses Linux::Event's asynchronous UDP hostname resolution and Net::QUIC's
verification of the original HTTPS origin. The existing Unblock pool owns
the operation and H3 multiplexing.

A Server with HTTP3 enabled binds a UDP socket on the same concrete host
and port as its TCP listener, using `tls => { cert_file => ..., key_file => ... }`.
`quic => { transport => { ... } }` forwards QUIC policy to Net::QUIC.
The same `on_headers` and `on_request` callbacks receive actual H3
transactions and Uniform messages.

Current limits: wildcard UDP binding, H3-only listeners, comprehensive QUIC
migration and packet-origin metadata are not supported yet. Graceful H3
shutdown, failure, cancellation, congestion and multi-connection coverage
pass their required Stage D integration regressions.
See the release notes for supported features and current limitations.

## HTTP/2

Install `Unblock::HTTP2 >= 0.13` and set `http2 => 1` on Client and Server.
Server HTTP/2 requires `tls => { cert_file => ..., key_file => ... }`; ALPN
selects HTTP/2 while HTTP/1 stays available by default. Set `http1 => 0` to
disable it. Cleartext HTTP/2 prior knowledge and h2c are not implemented.

The same request callbacks receive actual HTTP2 Transactions and Uniform
messages. Protocol-specific engine tuning belongs in `http2 => { ... }`.
Client `http_version => '2'` is strict; ordinary requests can negotiate
HTTP/1 fallback. Cancelled H2 streams leave sibling streams active. Server
`shutdown` sends GOAWAY and drains admitted streams before its grace deadline.

`on_error` retains the engine callback arguments; HTTP/2 can supply a third
protocol error-code argument. With Perl signatures, use an optional argument
or `@protocol_details` as in the example above.

## Implementation and dependencies

Native borrowed HTTP/1 and HTTP/2 input is the default. `native_input => 0` selects the ordinary
Perl input path for comparisons and diagnostics. Both paths share lifecycle
callbacks; the native path adapts the two distinct ABIs and retains the host
across callbacks that can close the stream. It contains no HTTP parser.
HTTP/2 native input uses its own checked ABI table; output uses the ordinary
attached host, respecting congestion until on_drain. Malformed protocol input
closes the affected connection without unwinding the reactor.

Current direct runtime requirements: Linux, Perl 5.36+, Linux::Event 0.117,
Unblock::HTTP 0.03, Unblock::HTTP1 0.13 and Uniform::HTTP 0.06.
These versions are published on CPAN; no development dependency checkout is
needed. HTTP2, HTTP3/Net::QUIC and WebSocket remain optional and are loaded
only when enabled. Enabling an unavailable engine produces an explicit error.
Server construction also checks HTTP1's graceful drain capability before
binding a listener. HTTP::CookieJar and Uniform::HTTP::Auth are not direct
dependencies of this integration layer.
The superseded private HTTP parsers, executors and public Request/Response
wrappers have been removed. The earlier implementation remains available
from the 0.003 release.

**WebSocket compatibility:** the separate `Linux::Event::WebSocket` 0.002
distribution uses the removed HTTP internals and cannot run with HTTP
0.004. Its coordinated **0.003 compatibility release** instead uses
`Unblock::HTTP1` directly, preserves the existing WebSocket client/server
API and does not depend on this distribution.

For a dedicated WebSocket application, use `Linux::Event::WebSocket` 0.003.
For WebSocket endpoints within an HTTP application, use this distribution's
`on_websocket` or `connect_websocket` convenience. Neither requires
choosing a WebSocket framing engine. Publish WebSocket 0.003 first, then
HTTP 0.004, to avoid breaking existing WebSocket installations.

In a shared-client, single-execution-slot HTTP/1.1 comparison using
Benchmark::Web, this rebuild exceeded Mojolicious throughput but trailed
Feersum, Hyperman and the original Linux::Event::HTTP significantly.
The documented HTTP/1 performance trade-off is accepted rather than
treated as an indefinite release blocker; see `docs/BENCHMARKING.md` for
matched workloads and caveats. See
[release notes](docs/RELEASE-0.004.md) and [architecture](docs/ARCHITECTURE.md)
provide the supported contract. Internal development handoffs are kept
in Git, not in the packaged distribution.

## Development checks

```sh
perl Makefile.PL
make
make test
REBUILD_NATIVE_INPUT=0 make test
```

`make test` runs `t/rebuild/*.t`, the new API contract's suite. The prior
implementation and its tests are preserved in the 0.003 release.

CI covers Perl 5.36, 5.38, 5.40, 5.42, 5.44, latest and latest threaded.
The release notes describe the tested scope. GitHub and CPAN publication
are separate maintainer actions.

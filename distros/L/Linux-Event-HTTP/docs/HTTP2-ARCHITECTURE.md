# Linux::Event::HTTP HTTP/2 architecture (Unblock rebuild)

HTTP/2 is an optional protocol of the rebuilt `Linux::Event::HTTP::Server`
and `Linux::Event::HTTP::Client`. Applications opt in with `http2 => 1`
or an engine tuning hash. HTTP2 uses TLS ALPN, not cleartext h2c or h2 prior
knowledge. The same callbacks and public classes handle HTTP1 and HTTP2.

The protocol implementation lives in the event-loop-independent
`Unblock::HTTP2` distribution. It owns nghttp2 framing, HPACK, SETTINGS,
GOAWAY, flow control, concurrent streams and stream cancellation.
`Unblock::HTTP` coordinates the application-facing transaction contract,
protocol selection and lifecycle. The application receives real Unblock
Transactions and Uniform Request/Response messages. The old
`Linux::Event::HTTP::_HTTP2` executors and custom message wrappers have
been removed in version 0.004.

Linux::Event::HTTP owns accepted Linux::Event TCP/TLS streams and client
connections. Its `_Transport` attaches the selected Unblock connection,
accepts bytes/EOF/errors and drains queued output. `_NativeStream` passes
borrowed input windows through the separate, version-checked
Unblock::HTTP2 native input ABI. `native_input => 0` uses the Perl input
path. Neither route implements a second HTTP/2 parser.

The Server supports multiplexed independent requests, response streaming,
flow-control drain and GOAWAY shutdown. The Client may request strict
`http_version => '2'` or negotiate HTTP/1 fallback. HTTP2 WebSocket and
generic Extended CONNECT use individual logical streams, preserving sibling
requests and the shared TLS connection.

`t/rebuild/50-http2.t`, `102-websocket-multiplex.t`,
`106-websocket-tls.t` and `107-generic-multiplex.t` exercise the actual
TCP/TLS path. With Unblock::HTTP2 0.13 or newer, the strict h2spec
v2.6.0 gate passed 147 of 147 cases with zero skips and zero failures
on the standalone Unblock engine, Linux::Event native input and
Linux::Event Perl input. All 147 case outcomes match across those paths.
This closes the HTTP/2 protocol conformance gate for the repaired engine,
without making any Linux::Event-specific change to Unblock.

Verified same-run CI: https://github.com/haxmeister/perl-Linux-Event-HTTP/actions/runs/40209116003
The current runtime and optional-dependency minimum is
`Unblock::HTTP2 >= 0.13`. Earlier results with 0.12 are historical,
not current conformance claims.

See `docs/ARCHITECTURE.md` for ownership boundaries and
`docs/RELEASE-0.004.md` for the release scope.

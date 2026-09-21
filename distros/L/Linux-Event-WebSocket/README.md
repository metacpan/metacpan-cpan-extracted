# Linux::Event::WebSocket

High-performance WebSocket client and server for Linux::Event, with a simple
callback-first API.

## Status

Release version: `0.001`.

The distribution provides working `ws://` and `wss://` client/server paths,
a native RFC 6455 data engine, and a production test suite. Version 0.001 is the
first CPAN release.

The GitHub Actions test matrix targets Perl 5.36 and Perl 5.44.0.

## What works today

- WebSocket client and server APIs.
- `ws://` and `wss://`.
- Text and binary messages.
- UTF-8 validation and decoding for text messages.
- Client masking and server unmasked output.
- Fragmented WebSocket messages with interleaved control frames.
- Automatic ping/pong control handling plus explicit `ping()`.
- Graceful WebSocket close handshake with a configurable close timeout.
- Hard transport abort when graceful close is not appropriate.
- Subprotocol negotiation.
- Access to the HTTP handshake request and response.
- Configurable message-size protection, defaulting to 16 MiB.
- Linux::Event Stream output buffering and backpressure.
- Linux::Event TLS transport retained across the HTTP-to-WebSocket transition.
- Same-read handoff: WebSocket bytes that arrive immediately after the HTTP
  Upgrade headers are preserved across the protocol transition.

## Server

```perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::WebSocket::Server;

my $loop = Linux::Event::Loop->new;

my $server = Linux::Event::WebSocket::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 8080,

    on_open => sub ($ws) {
        $ws->send_text('hello');
    },

    on_message => sub ($ws, $payload, $type) {
        if ($type eq 'text') {
            $ws->send_text("echo: $payload");
        }
    },

    on_close => sub ($ws, $code, $reason) {
        # Connection finished.
    },
);

$loop->run;
```

For `wss://`, pass the normal Linux::Event HTTP server `tls` policy containing
the certificate and key.

## Client

```perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::WebSocket::Client;

my $loop = Linux::Event::Loop->new;

my $client = Linux::Event::WebSocket::Client->new(
    loop => $loop,

    on_open => sub ($ws) {
        $ws->send_text('hello');
    },

    on_message => sub ($ws, $payload, $type) {
        say $payload if $type eq 'text';
    },

    on_close => sub ($ws, $code, $reason) {
        $loop->stop;
    },
);

$client->connect('wss://example.com/socket');
$loop->run;
```

## Connection API

Established client and server connections share the common
`Linux::Event::WebSocket::Connection` API. Important operations include:

```perl
$ws->send_text($text);
$ws->send_binary($bytes);
$ws->ping($bytes);
$ws->close(code => 'SUCCESS', reason => 'done');
$ws->abort;

$ws->is_open;
$ws->is_closing;
$ws->subprotocol;
$ws->secure;
$ws->url;
$ws->handshake_request;
$ws->handshake_response;
$ws->data;
```

`close()` starts the WebSocket close handshake. `abort()` closes the underlying
transport immediately.

## Architecture

Linux::Event::WebSocket deliberately composes the existing ecosystem instead of
reimplementing each layer:

```text
Linux::Event
    socket, TLS, ordered bytes, buffering, backpressure, lifecycle
        |
Linux::Event::HTTP
    HTTP/1.1 opening Upgrade and live-stream handoff
        |
Linux::Event::WebSocket
    WebSocket connection API, RFC 6455 framing, messages, masking,
    fragmentation, control semantics, and protocol policy
```

A successful HTTP Upgrade calls Linux::Event's in-place `transition_to()` on the
same live connection. The socket, TLS transport, queued output, application
state, and already-read post-HTTP bytes stay attached.

There is no second miniature HTTP parser in this distribution.

## Inheritance policy

Connection classes use ordinary single inheritance only:

```text
Linux::Event::WebSocket::Client::Connection
    -> Linux::Event::WebSocket::Connection
    -> Linux::Event::IO::Sock::Stream
```

and separately:

```text
Linux::Event::WebSocket::Server::Connection
    -> Linux::Event::WebSocket::Connection
    -> Linux::Event::IO::Sock::Stream
```

There are no Perl roles, mixins, multiple-inheritance trees, or method injection
in the connection design.

## Protocol engine

The production RFC 6455 data engine is native code kept behind private modules.
A small, vendored copy of `bq_websocket` performs framing, masking,
fragmentation, message assembly, and control-frame processing. A thin XS
adapter connects it to Linux::Event's existing Stream; bq does not own the
socket, TLS, HTTP Upgrade, timers, or event loop.

Inbound and outbound text use Perl's C UTF-8 API from XS to enforce the RFC
3629 boundary without a Perl-level validation pass. Client frame masks use
Linux `getrandom(2)`. The opening HTTP handshake remains entirely owned by
Linux::Event::HTTP and this distribution's handshake policy.

The older private `_Frame` and `_Parser` helpers remain useful for tests and
developer benchmarks, but they are not the production data-path parser.

## Protocol policy

The wrapper enforces peer-side RFC 6455 rules that should not depend on a generic
transport-neutral parser, including:

- clients must mask frames sent to servers;
- servers must not mask frames sent to clients;
- RSV bits are rejected while no extensions are negotiated;
- control frames must be final and no larger than 125 bytes;
- close payload, status-code, and UTF-8 reason validation;
- frame/message size limits before accepting large advertised payloads.

## Native-code policy

Measured end-to-end, Unicode, concurrency, and broadcast workloads justified a
WebSocket-specific native engine in this distribution. The native code stays
here rather than in Linux::Event core because RFC 6455 framing and policy are
WebSocket-specific.

The vendored engine is intentionally transport-neutral in this integration:
Linux::Event continues to own epoll, sockets, TLS, buffering, backpressure, and
lifecycle. No external bq system library is required.

The vendored bq source is based on upstream commit
`6c188d3f0edca38d7a8926e0d30f4c145414ba4c` and is carried under the MIT
license. Linux::Event-specific fixes are documented in
`vendor/bq_websocket/README.md`; the full third-party license text is in
`vendor/bq_websocket/LICENSE`.

See `docs/ARCHITECTURE.md` for the detailed design, `docs/BENCHMARKS.md`
for the measurement rationale, and `handoff.md` for the current development
state.

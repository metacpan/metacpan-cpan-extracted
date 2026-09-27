# Linux::Event::HTTP

**Native HTTP/1.x and HTTP/2 client/server support for Linux::Event.**

Linux::Event::HTTP is a Linux-focused HTTP protocol layer built on
[Linux::Event](https://metacpan.org/pod/Linux::Event). It provides asynchronous
HTTP servers and clients without turning the protocol layer into a web
framework.

The same public Request, Response, Transaction, Client, and Server model is used
for HTTP/1 and HTTP/2.

- HTTP/1.x is built in.
- HTTP/2 is optional and uses Net::HTTP2::nghttp2/libnghttp2.
- HTTPS and HTTP/2 use Linux::Event TLS.
- HTTP/2 is negotiated with ALPN and falls back to HTTP/1.1 on the same
  high-level API.
- Request and response bodies are streaming-first and bounded when buffered.
- HTTP/1 Upgrade and CONNECT can hand the same live Linux::Event stream to
  another protocol.

## Server

A basic HTTP/1 server:

```perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::HTTP::Server;

my $loop = Linux::Event::Loop->new;

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 8080,

    on_request => sub ($conn, $req, $res) {
        $res->header('Content-Type', 'text/plain');
        $res->body("hello\n");
    },
);

$loop->run;
```

The callback receives the persistent HTTP connection, the Request, and the
Response for that exchange.

Setting a scalar response body during the callback is enough. The response is
committed after the callback returns.

### HTTPS with HTTP/2

Enable HTTP/2 on the same Server API:

```perl
my $server = Linux::Event::HTTP::Server->new(
    loop  => $loop,
    host  => '0.0.0.0',
    port  => 8443,
    http2 => 1,

    tls => {
        cert_file => '/path/server-cert.pem',
        key_file  => '/path/server-key.pem',
    },

    on_request => sub ($conn, $req, $res) {
        $res->header('Content-Type', 'text/plain');
        $res->body("hello over HTTP " . $req->version . "\n");
    },
);
```

The server advertises `h2` before `http/1.1`. If the peer selects HTTP/2,
Linux::Event::HTTP uses its HTTP/2 executor. Otherwise the connection continues
as HTTP/1.1.

HTTP/2 requires Net::HTTP2::nghttp2 0.011 or newer.

## Client

```perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::HTTP::Client;

my $loop = Linux::Event::Loop->new;
my $client = Linux::Event::HTTP::Client->new(
    loop  => $loop,
    http2 => 1,
);

my $operation = $client->get(
    'https://example.com/',

    buffer_body => 1_048_576,

    on_complete => sub ($tx) {
        my $res = $tx->response;

        say $res->status;
        say $res->body;

        $client->close;
        $loop->stop;
    },

    on_error => sub ($tx, $error) {
        warn $error;
        $client->close;
        $loop->stop;
    },
);

$loop->run;
```

With `http2 => 1`, direct HTTPS requests negotiate HTTP/2 with ALPN and fall
back to HTTP/1.1 when needed. Selected HTTP/2 connections can carry concurrent
streams for the same origin.

Without `buffer_body`, response bodies are not accumulated automatically.
Use `on_body` to consume them incrementally.

## The object model

Linux::Event::HTTP keeps message data separate from exchange and connection
state:

```text
Request + Response
       |
       v
  Transaction       one HTTP exchange
       |
       v
Client::Operation   one high-level client action
                    (may contain multiple Transactions)

Connection          persistent transport/protocol executor
Server / Client     high-level endpoint policy
```

The important distinction is:

- **Request** and **Response** are HTTP messages.
- **Transaction** is exactly one Request/Response exchange.
- **Client::Operation** is one high-level client action. Redirects and automatic
  authentication retries create additional Transactions.
- **Connection** owns persistent protocol execution.
- **Linux::Event** still owns sockets, TLS, readiness, buffering, and transport
  backpressure.

## Request and response bodies

### Complete scalar bodies

For a complete body already in memory:

```perl
$res->body($bytes);
```

or:

```perl
$client->post(
    $url,
    body => $bytes,
    ...
);
```

### Streaming server responses

```perl
on_request => sub ($conn, $req, $res) {
    my $body = $conn->transaction->response_body(
        on_drain  => sub ($body) { ... },
        on_cancel => sub ($body) { ... },
    );

    $body->write($chunk);
    $body->complete($final_chunk);
},
```

### Streaming client requests

```perl
my $operation = $client->post(
    $url,
    stream_body => {
        on_drain  => sub ($body) { ... },
        on_cancel => sub ($body) { ... },
    },
    ...
);

my $body = $operation->request_body;
$body->write($chunk);
$body->complete;
```

`write` follows Linux::Event backpressure semantics:

```text
true  = bytes accepted; producer may continue
false = bytes accepted; pause until on_drain
```

Incoming bodies are incremental-first. If no body callback is installed, the
library drains the body rather than silently building an unbounded scalar.

For a bounded client response buffer:

```perl
$client->get(
    $url,
    buffer_body => 4 * 1024 * 1024,
    on_complete => sub ($tx) {
        my $bytes = $tx->response->body;
        ...
    },
);
```

## Redirects, cookies, and authentication

The high-level Client handles ordinary HTTP client policy without moving that
policy into Request or Response objects.

Redirects:

- 301, 302, 303, 307, and 308 are followed by default.
- The default redirect limit is 5.
- Each followed hop is a separate Transaction.
- Streaming request producers are not automatically replayed.

Cookies:

- Cookie policy is supplied by an application-owned `HTTP::CookieJar`.
- Linux::Event::HTTP does not create a global or implicit cookie store.

Authentication:

- Authentication mechanics are delegated to `Uniform::HTTP::Auth`.
- Target 401 and proxy 407 retries become additional Transactions.
- Streaming request producers are not automatically replayed.

See the Client POD and `docs/CLIENT-POLICY.md` for the detailed policy rules.

## HTTP/2 behavior

HTTP/2 is intentionally integrated into the existing high-level HTTP API rather
than exposed as a separate public library.

Current HTTP/2 support includes:

- TLS ALPN negotiation;
- high-level Server and Client integration;
- multiplexed client requests;
- streaming request and response bodies;
- redirects, cookies, and authentication policy across HTTP/2 exchanges;
- decoded header-list limits;
- per-connection aggregate buffered-response limits;
- GOAWAY draining;
- stream-local failure where the protocol permits it.

Important current boundaries:

- HTTP/2 is enabled explicitly with `http2 => 1`.
- The production HTTP/2 path is direct HTTPS negotiated with ALPN.
- Cleartext h2c is not provided.
- Forward-proxy requests, HTTP/1 Upgrade, CONNECT stream handoff, and explicit
  HTTP version selection currently use the HTTP/1 path.
- HTTP/2 currently requires the default high-level connection class.
- Transparent replay after GOAWAY is not attempted without reliable
  last-stream-id information.

See `docs/HTTP2-ARCHITECTURE.md` for implementation and protocol boundaries.

## Upgrade and CONNECT

HTTP/1.1 Upgrade and CONNECT are lifecycle operations on Transaction rather than
methods on Response.

Server Upgrade:

```perl
$res->header('Upgrade', 'my-protocol');
$conn->transaction->upgrade('MyProtocolConnection');
```

Server CONNECT:

```perl
if ($req->method eq 'CONNECT') {
    $conn->transaction->tunnel('MyTunnelConnection');
}
```

The live Linux::Event stream is transitioned in place, preserving already-read
post-HTTP bytes for the new protocol.

The high-level Client also provides `connect_tunnel()` for explicit proxy
CONNECT establishment.

## Connection reuse

HTTP/1 connections are persistent when normal HTTP framing permits reuse.

HTTP/2 connections are pooled per origin and can carry concurrent streams.
Connections that receive GOAWAY stop accepting new operations and drain existing
streams.

## Public modules

Most applications need only:

- `Linux::Event::HTTP::Server`
- `Linux::Event::HTTP::Client`
- `Linux::Event::HTTP::Request`
- `Linux::Event::HTTP::Response`
- `Linux::Event::HTTP::Transaction`
- `Linux::Event::HTTP::Client::Operation`

Advanced HTTP/1 users may also use the public Client::Connection and
Server::Connection classes directly.

## Installation

HTTP/1 support uses the normal distribution dependencies.

HTTP/2 additionally requires:

```text
Net::HTTP2::nghttp2 >= 0.011
```

The HTTP/2 binding is optional so an HTTP/1-only installation does not need
libnghttp2.

## Build and test

```sh
perl Makefile.PL
make
make test
```

For a release-style distribution check:

```sh
make disttest
```

## Design and maintainer documentation

- `docs/ARCHITECTURE.md` - ownership and lifecycle design
- `docs/HTTP2-ARCHITECTURE.md` - HTTP/2 integration and limits
- `docs/CLIENT-POLICY.md` - redirects, cookies, authentication, and proxy policy
- `docs/CONNECT.md` - CONNECT tunnel semantics
- `docs/BENCHMARKING.md` - benchmark harnesses and measurement rules
- `docs/PICOHTTPPARSER-EXPERIMENT.md` - HTTP/1 parser provenance and evaluation

## Scope

Linux::Event::HTTP is a protocol and communications layer.

It deliberately does not provide routing, templates, sessions, application
middleware, or a web-framework object model. Those can be built above the HTTP
layer without making the transport and protocol APIs framework-specific.

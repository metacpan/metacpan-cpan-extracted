# Linux::Event::HTTP

Build HTTP servers and make HTTP requests with [Linux::Event](https://metacpan.org/pod/Linux::Event). HTTP/1.1 works out of the box. HTTP/2 and HTTP/3 are optional.

This module handles the HTTP connection for you. You provide callbacks to receive requests, send responses, or handle errors.

**Requirements:** Linux and Perl 5.36 or newer.

## Install

```sh
cpanm Linux::Event::HTTP
```

## Your first server

Save as `server.pl`:

```perl
#!/usr/bin/env perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::HTTP::Server;

my $loop = Linux::Event::Loop->new;

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 8080,

    on_request => sub ($tx, $req) {
        $tx->respond(
            status => 200,
            headers => [['content-type', 'text/plain']],
            body => "Hello from Linux::Event!\n",
        );
    },
);

say "Listening on http://127.0.0.1:8080/";
$loop->run;
```

Start it with `perl server.pl`. In another terminal, run:

```sh
curl http://127.0.0.1:8080/
```

The `on_request` callback runs when the entire request has arrived. `$req` is the incoming request; `$tx` is the transaction used to reply. The server keeps running until you stop it.

## Your first client

Save as `client.pl`:

```perl
#!/usr/bin/env perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::HTTP::Client;

my $loop = Linux::Event::Loop->new;
my $client = Linux::Event::HTTP::Client->new(loop => $loop);

$client->get(
    'https://example.com/',
    timeout => 15,

    on_response => sub ($tx, $res) {
        say "HTTP ", $res->status;
        say $res->body;
    },

    on_error => sub ($object, $error, @details) {
        warn "Request failed: $error\n";
    },

    on_finish => sub { $loop->stop },
);

$loop->run;
```

Run `perl client.pl`. The client waits asynchronously for the server. By default, **`on_response` runs after the whole response body has arrived**. `on_error` handles connection and protocol failures. `on_finish` runs at the end of either outcome, so it is a convenient place to stop a one-request program.

An HTTP response like 404 or 500 is still an HTTP response; inspect `$res->status`. It is not necessarily a connection error.

## Next steps

Read the [Getting Started guide](docs/GETTING-STARTED.md) for these everyday tasks:

- GET, POST, request headers, and response bodies
- Responding to different paths and methods
- Understanding callbacks and streaming large bodies
- HTTPS and enabling HTTP/2 or HTTP/3
- Cancelling requests and shutting down a server

The public interfaces are [Client](https://metacpan.org/pod/Linux::Event::HTTP::Client) and [Server](https://metacpan.org/pod/Linux::Event::HTTP::Server). You can use one client for many requests, and a server can handle many connections.

## Protocols and advanced features

HTTP/1.1 is enabled by default. For HTTP/2, install `Unblock::HTTP2` 0.13+ and set `http2 => 1`; servers also need TLS. For HTTP/3, install `Unblock::HTTP3` 0.14+ and `Net::QUIC` 0.06+, then set `http3 => 1` and configure TLS. HTTP/3 servers require a concrete listener host and run alongside a TCP listener. WebSocket and CONNECT handoff are also available.

Linux::Event manages sockets, TLS, and timers. [Unblock::HTTP](https://metacpan.org/pod/Unblock::HTTP) manages HTTP transactions and connection pooling; [Uniform::HTTP](https://metacpan.org/pod/Uniform::HTTP) supplies request and response objects. You **do not** need to learn these internals to make ordinary HTTP requests.

For more detail, see [Architecture](docs/ARCHITECTURE.md), [CONNECT handoff](docs/CONNECT.md), [Benchmarking](docs/BENCHMARKING.md), and the [0.005 release notes](docs/RELEASE-0.005.md). Version 0.004 replaced the former public API; see the [0.004 release notes](docs/RELEASE-0.004.md) before migrating older applications.

## Development

```sh
perl Makefile.PL
make
make test
```

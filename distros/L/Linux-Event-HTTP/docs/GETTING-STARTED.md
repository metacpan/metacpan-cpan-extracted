# Getting started with Linux::Event::HTTP

This guide assumes Linux, Perl 5.36+, and `Linux::Event::HTTP` installed from CPAN. Start with the two complete examples in the [README](../README.md). The examples below build on those same `$loop`, `$client`, or `$server` objects.

## Make an HTTP request

For a GET, call `get($url, %options)`. For a POST, use `post`. The Client also has `head`, `put`, and `delete` methods.

```perl
$client->post(
    'https://example.com/messages',
    headers => [['content-type', 'text/plain']],
    body => "Hello\n",
    timeout => 15,
    on_response => sub ($tx, $res) {
        say "Status: ", $res->status;
        say "Content type: ", ($res->header('content-type') // 'none');
        say "Body: ", $res->body;
    },
    on_error => sub ($object, $error, @details) {
        warn "Request failed: $error\n";
    },
    on_finish => sub { $loop->stop },
);
```

Use `request(method => 'PATCH', url => $url, ...)` when you need another HTTP method.

Header arguments are an array of name/value pairs, such as `[['accept', 'application/json']]`. Response and request objects provide `header('name')` to read a header; header names are case-insensitive. For multiple values of the same name, use `header_values('name')`.

`$res->status` is the HTTP status code. A 404 or 500 does **not** automatically mean `on_error` runs: you received a valid HTTP response and should examine its status.

### When does the client callback run?

| Callback | When it runs |
| --- | --- |
| `on_response($tx, $res)` | After the full response, unless you supply `on_data` |
| `on_data($tx, $bytes)` | For each response body chunk, when streaming is enabled |
| `on_end($tx)` | When a streamed response body finishes successfully |
| `on_error($object, $error, @details)` | For an operation failure, including a timeout |
| `on_finish(...)` | When the operation ends, whether successful, failed, or cancelled |

**Important:** When you include `on_data`, `on_response` runs as soon as response **headers** arrive. Otherwise the body is buffered and `on_response` runs only when the full response is ready.

`on_finish` is the best place to call `$loop->stop` in a standalone program making one request. In a longer-lived app, leave the loop running. The Client can issue many requests from one object.

### Read a response as it arrives

For a large response, process chunks without buffering the whole body:

```perl
$client->get(
    'https://example.com/large-file',
    timeout => 30,
    on_response => sub ($tx, $res) {
        say "HTTP ", $res->status;  # Headers have arrived
    },
    on_data => sub ($tx, $bytes) {
        print $bytes;               # A chunk of the body
    },
    on_end => sub ($tx) {
        say "\nComplete";
    },
    on_error => sub ($object, $error, @details) {
        warn "Failed: $error\n";
    },
    on_finish => sub { $loop->stop },
);
```

Without streaming, response buffering is bounded (1 MiB by default). If the body crosses that limit, the request fails and `on_error` runs; `on_response` will not receive a partial body. **If you don't know how large the response will be, use `on_data` from the beginning.** It works with small responses too. The Client cannot automatically switch to streaming after reaching the buffer limit because there would be nowhere to deliver the remaining bytes without an `on_data` callback. The `Content-Length` header is not always available or a reliable size prediction.

### Cancel a request

Requests return an operation handle immediately, even if the network connection is still being established.

```perl
my $op = $client->get(
    'https://example.com/',
    timeout => 15,
    on_response => sub ($tx, $res) { say $res->status },
);
$op->cancel;  # If no longer needed
```

The handle also provides `state`, `error`, `is_terminal`, and `transaction`. A transaction may not exist until a queued request is admitted.

## Handle requests on a server

Use `on_request` to respond after a full incoming request has been received. The `$req` object provides `method`, `target`, `body`, and `header`. The `$tx` object sends the response.

This callback can go into the server constructor from the README:

```perl
on_request => sub ($tx, $req) {
    if ($req->method eq 'GET' && $req->target eq '/') {
        $tx->respond(status => 200, body => "Welcome\n");
    }
    elsif ($req->method eq 'POST' && $req->target eq '/echo') {
        $tx->respond(
            status => 200,
            headers => [['content-type', 'text/plain']],
            body => $req->body,
        );
    }
    else {
        $tx->respond(status => 404, body => "Not found\n");
    }
},
```

`target` contains the request path and, if present, its query string. For example, `/items?page=2` is different from `/items`. Routing and query parsing are up to the application; this module is not a web framework.

### Read incoming data in chunks

Normally `on_request` runs after the whole request body is available in `$req->body`. For an incoming upload, register a data callback at the header stage:

```perl
on_headers => sub ($tx, $req) {
    $tx->on_data(sub ($tx, $bytes) {
        # Process each incoming body chunk.
        say "Received ", length($bytes), " bytes";
    });
},
on_request => sub ($tx, $req) {
    # Called after the successfully streamed request has ended.
    # The body was not collected into $req->body.
    $tx->respond(status => 200, body => "Upload received\n");
},
```

For a body that fails or is cancelled, `on_request` does not run. By default, non-streamed bodies are limited to 1 MiB; `http1 => { max_buffered_body_bytes => $bytes }` adjusts this for HTTP/1.

### Send a response in chunks

```perl
on_request => sub ($tx, $req) {
    $tx->respond(status => 200, stream_body => 1);
    $tx->write("First part\n");
    $tx->end("Last part\n");
},
```

For large or slow responses, use `on_drain` and observe backpressure. A false return from `write` means the data **was accepted** but the producer must stop until it is told to resume. Do not send the same bytes again.

## HTTPS and HTTP versions

For an HTTPS server, supply a certificate and private key:

```perl
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 8443,
    tls => { cert_file => 'cert.pem', key_file => 'key.pem' },
    on_request => sub ($tx, $req) {
        $tx->respond(status => 200, body => "Secure\n");
    },
);
```

A client verifies server certificates and hostnames by default. For a private CA, pass `tls => { ca_file => 'ca.pem' }` to `Client->new`. Do not disable certificate verification for ordinary use.

HTTP/1.1 needs no protocol option. To enable HTTP/2, install `Unblock::HTTP2` 0.13+ and set `http2 => 1` on the client or server; HTTP/2 servers require TLS. To enable HTTP/3, install `Unblock::HTTP3` 0.14+ and `Net::QUIC` 0.06+, set `http3 => 1`, and supply TLS credentials on the server. HTTP/3 servers need a concrete host and run alongside a TCP listener. These options do not change the ordinary request callbacks.

A client can require a protocol with `http_version => '2'` or `http_version => '3'` on a request. If it cannot use that protocol, the strict request fails rather than silently falling back.

## Shutting down

`$server->close` stops accepting new TCP connections while admitted work can continue. To shut down gracefully, use:

```perl
$server->shutdown(
    grace => 30,
    on_complete => sub ($server) {
        $loop->stop;
    },
);
```

Grace is in seconds. The completion callback may be invoked immediately if there is nothing to drain. `$client->shutdown` cancels queued work and retires connections, allowing active requests to finish.

## More details

For public methods, consult `perldoc Linux::Event::HTTP::Client` and `perldoc Linux::Event::HTTP::Server`.

The [architecture](ARCHITECTURE.md), [benchmark results](BENCHMARKING.md), [generic CONNECT guide](CONNECT.md), and [release notes](RELEASE-0.004.md) cover technical design, advanced protocols, and migration details. The underlying [Unblock::HTTP](https://metacpan.org/pod/Unblock::HTTP) and [Uniform::HTTP](https://metacpan.org/pod/Uniform::HTTP) documentation is useful when you need more control, but is not required for basic client and server work.

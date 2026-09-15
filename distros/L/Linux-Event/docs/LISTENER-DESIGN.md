# Stream socket listener design

`Linux::Event::IO::Sock::Listener` owns a listening Linux `SOCK_STREAM`
socket and generates one configured `Linux::Event::IO::Sock::Stream` for each
accepted connection.

The central model is:

> A Listener is a Stream generator.

Listener configuration therefore has two distinct scopes:

- top-level options configure the listening socket and accept engine;
- `stream => { ... }` is the resolved recipe for generated connections.

This boundary keeps bind/listen/accept policy separate from established
ordered-byte connection policy without forcing applications to create a Stream
subclass for simple servers.

## Public API

A raw server can use the default Stream class directly:

```perl
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 9999,

    backlog             => 4096,
    max_accept_per_tick => 256,

    stream => {
        on_data => sub ($stream, $bytes) {
            $stream->write($bytes);
        },
    },

    on_accept => sub ($listener, $stream) {
        # Listener lifecycle callback
    },
);
```

A reusable protocol can still name a Stream subclass:

```perl
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '0.0.0.0',
    port => 9000,
    stream => {
        class => 'My::Connection',
        data  => $initial_connection_state,
        tuning => {
            read_size         => 131_072,
            read_budget_bytes => 524_288,
            idle_timeout      => 30,
        },
        on_error => sub ($stream, $error) {
            warn "$error\n";
        },
    },
);
```

`class` defaults to `Linux::Event::IO::Sock::Stream`.

## Listener-owned settings

The following options remain top-level because they configure the listening
resource or accept engine:

- `loop`
- `host`
- `port`
- `unix`
- `fh`
- `owns_socket`
- `backlog`
- `max_accept_per_tick`
- `edge_triggered`
- `reuseaddr`
- `reuseport`
- `v6only`
- `bind_device`
- Unix listener ownership and permissions
- Listener callbacks such as `on_accept` and `on_error`

`backlog` defaults to 4096. `max_accept_per_tick` defaults to 256. Zero drains
acceptance until `EAGAIN` and is required by edge-triggered operation.

Unix listener policy additionally includes `unlink`, `unlink_on_close`, and
optional `permissions`.

Exactly one socket source is selected:

- `host => ..., port => ...` creates an Internet listener;
- `unix => ...` creates a filesystem Unix-domain listener;
- `fh => ...` adopts an existing listening socket.

## Generated Stream recipe

The nested `stream` hash describes each generated connection. Supported policy
includes:

```perl
stream => {
    class => 'My::Connection',

    tuning => {
        read_size          => 65_536,
        read_budget_bytes  => 262_144,
        read_batch_bytes   => 0,
        message_batch_size => 0,
        high_watermark     => 1_048_576,
        low_watermark      => 262_144,
        max_pending_bytes  => 0,
        max_buffer         => 8_388_608,
        idle_timeout       => 60,
        read_timeout       => 0,
        write_timeout      => 0,
    },

    tls => {
        cert_file => $cert_file,
        key_file  => $key_file,
    },

    data => $initial_data,

    on_data            => sub { ... },
    on_message         => sub { ... },
    on_messages        => sub { ... },
    on_ready           => sub { ... },
    on_transport_ready => sub { ... },
    on_drain           => sub { ... },
    on_eof             => sub { ... },
    on_error           => sub { ... },
    on_close           => sub { ... },
}
```

Recipe callback CVs are retained once. Linux::Event does not manufacture a new
closure for every connection.

## Recipe preparation

The Listener resolves the generated-Stream recipe during construction, before
it begins accepting traffic. The prepared recipe contains:

- the resolved Stream class and cached class descriptor;
- validated effective callback CVs;
- effective initial tuning values;
- optional prepared TLS server context and policy;
- initial connection data;
- normalized construction state.

This is a cold-path operation. Per-accept work consumes the prepared recipe and
does not repeat class-policy resolution or configuration merging.

## Validation boundary

Generated-Stream validity is checked when the Listener is constructed.

A raw readable Stream requires an effective `on_data` callback. A framed Stream
requires the message sink selected by its framing and batching policy unless a
native consumer supplies that sink.

Examples such as `stream => {}` therefore fail immediately instead of waiting
for the first client connection.

Framing remains class policy declared through `Linux::Event::Framer`; the
Listener recipe does not redefine framing.

## Stream tuning precedence

Accepted connection tuning has three precedence levels:

1. class defaults from `stream_tuning()`;
2. Listener recipe overrides from `stream => { tuning => {...} }`;
3. live per-object overrides from `$stream->tune(...)`.

The effective mutable values live in each Stream's native state. The steady
read/write path does not perform Perl hash lookups, class-vs-instance
resolution, or recipe parsing.

Live tuning changes are deterministic:

- changing `message_batch_size` settles work owned by the previous batching
  policy before the new policy becomes visible;
- changed high/low watermarks immediately reconcile current backpressure;
- lowering `max_pending_bytes` does not discard already queued output, but
  future queue growth must satisfy the new limit;
- lowering `max_buffer` does not discard already retained input, but future
  growth must satisfy the new limit;
- timeout changes re-arm or cancel deadline state as required.

Framer identity, callback structure, native-consumer identity, and transport
kind are not live tuning values.

## TLS acquisition policy

TLS belongs to connection acquisition, not to the Stream class identity.

```perl
my $secure = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '0.0.0.0',
    port => 9443,
    stream => {
        class => 'My::Connection',
        tls => {
            cert_file => $cert_file,
            key_file  => $key_file,
            alpn      => ['my-protocol/1'],
        },
    },
);

my $plain = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 9000,
    stream => {
        class => 'My::Connection',
    },
);
```

Both listeners can generate the same Stream class. The first acquires TLS
connections and the second acquires plain connections.

A Stream subclass may define `tls_defaults()` for reusable server policy such
as ALPN and handshake/shutdown timeouts. Those defaults do not activate TLS.
Only `stream => { tls => {...} }` selects TLS for accepted connections.

Ordinary server applications do not need to load `Linux::Event::TLS` directly.
The Listener lazily loads the provider when a TLS recipe is present.

## Prepared TLS server context

During Listener construction, TLS setup:

1. resolves optional class TLS defaults;
2. merges Listener deployment overrides;
3. validates the effective server configuration;
4. loads certificate/key material;
5. creates one reusable server `SSL_CTX` template.

Each accepted TLS connection then allocates only its independent per-connection
SSL state, binds the accepted descriptor, and attaches the existing native
Stream transport ABI.

Ordinary TLS reads, writes, handshakes, and shutdowns do not perform Perl
configuration lookup or certificate parsing. Plain Streams allocate no TLS
connection state.

`bench/run-tls-accept-setup-bench.pl` measures fresh per-connection server
context construction against cloning connection state from the prepared
Listener-style context. `bench/run-tls-microbench.pl` remains the separate
steady-state encrypted I/O benchmark.

## Accept sequence

Native code drains `accept4()` with atomic `SOCK_NONBLOCK | SOCK_CLOEXEC`
flags. Each accepted descriptor follows this sequence:

```text
accept4
  -> clone per-connection TLS state if the recipe enables TLS
  -> construct resolved Stream class from the prepared recipe
  -> attach Stream to the Listener's Loop
  -> Listener on_accept
  -> plain on_ready, or TLS handshake then on_ready
```

`on_accept` observes the fully constructed Stream object. For TLS it runs after
attachment, while application `on_ready` waits for transport handshake and
verification.

An `on_accept` exception closes only that accepted connection and reports a
nonfatal callback error through the Listener error policy.

## Socket policy and protocol policy

Established socket policy remains class policy through `socket_options()` and
the cached cold-path `configure_socket()` hook.

Core Listener/Stream policy should remain generic. Examples:

- listen backlog belongs to Listener core;
- byte I/O timeouts belong to Stream tuning;
- TLS certificate/key acquisition belongs to the Stream recipe;
- HTTP keepalive belongs to an HTTP layer;
- request-count or worker-recycling policy belongs above core.

The Listener recipe is deployment configuration for generated connections, not
a place to accumulate protocol-server framework policy.

## Lifecycle

`pause()` and `resume()` control acceptance without closing the listening
socket. `close()` ends Listener ownership. `detach()` removes Loop readiness and
returns the still-open listening handle according to the ownership contract.

`state()` reports Listener lifecycle such as `unattached`, `listening`,
`paused`, `closed`, `failed`, and `detached`.

Runtime failures use `Linux::Event::Error`. Resource exhaustion such as
`EMFILE` pauses acceptance before error delivery so a readable backlog cannot
create a tight error loop.

## Private implementation boundary

`Linux::Event::_Socket::Listener` is the private accept-engine boundary beneath
`Linux::Event::IO::Sock::Listener`. It is not an alternate public Listener API.

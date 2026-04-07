# NAME

EV::Redis - Asynchronous redis client using hiredis and EV

# SYNOPSIS

    use EV::Redis;
    
    my $redis = EV::Redis->new;
    $redis->connect('127.0.0.1');
    
    # or
    my $redis = EV::Redis->new( host => '127.0.0.1' );
    
    # command
    $redis->set('foo' => 'bar', sub {
        my ($res, $err) = @_;
    
        print $res; # OK
    
        $redis->get('foo', sub {
            my ($res, $err) = @_;
    
            print $res; # bar
    
            $redis->disconnect;
        });
    });
    
    # start main loop
    EV::run;

# DESCRIPTION

EV::Redis is a fork of [EV::Hiredis](https://metacpan.org/pod/EV%3A%3AHiredis) by Daisuke Murase (typester),
extended with reconnection, flow control, TLS, and RESP3 support. It is a
drop-in replacement: the API is fully backward-compatible with EV::Hiredis.

This is an asynchronous client for Redis using hiredis and [EV](https://metacpan.org/pod/EV) as backend.
It connects to [EV](https://metacpan.org/pod/EV) with C-level interface so that it runs faster.

# ANYEVENT INTEGRATION

[AnyEvent](https://metacpan.org/pod/AnyEvent) has a support for EV as its one of backends, so [EV::Redis](https://metacpan.org/pod/EV%3A%3ARedis) can be used in your AnyEvent applications seamlessly.

# NO UTF-8 SUPPORT

Unlike other redis modules, this module doesn't support utf-8 string.

This module handle all variables as bytes. You should encode your utf-8 string before passing commands like following:

    use Encode;
    
    # set $val
    $redis->set(foo => encode_utf8 $val, sub { ... });
    
    # get $val
    $redis->get(foo, sub {
        my $val = decode_utf8 $_[0];
    });

# METHODS

## new(%options);

Create new [EV::Redis](https://metacpan.org/pod/EV%3A%3ARedis) instance.

Available `%options` are:

- host => 'Str'
- port => 'Int'

    Hostname and port number of redis-server to connect. Mutually exclusive with `path`.

- path => 'Str'

    UNIX socket path to connect. Mutually exclusive with `host`.

- on\_error => $cb->($errstr)

    Error callback will be called when a connection level error occurs.
    If not provided (or `undef`), a default handler that calls `die` is
    installed. To have no error handler, call `$obj->on_error(undef)`
    after construction.

    This callback can be set by `$obj->on_error($cb)` method any time.

- on\_connect => $cb->()

    Connection callback will be called when connection successful and completed to redis server.

    This callback can be set by `$obj->on_connect($cb)` method any time.

- on\_disconnect => $cb->()

    Disconnect callback will be called when disconnection occurs (both normal and error cases).

    This callback can be set by `$obj->on_disconnect($cb)` method any time.

- on\_push => $cb->($reply)

    RESP3 push callback for server-initiated out-of-band messages (Redis 6.0+).
    Called with the decoded push message (an array reference). This enables
    client-side caching invalidation and other server-push features.

    This callback can be set by `$obj->on_push($cb)` method any time.

- connect\_timeout => $num\_of\_milliseconds

    Connection timeout.

- command\_timeout => $num\_of\_milliseconds

    Command timeout.

- max\_pending => $num

    Maximum number of commands sent to Redis concurrently. When this limit is reached,
    additional commands are queued locally and sent as responses arrive.
    0 means unlimited (default). Use `waiting_count` to check the local queue size.

- waiting\_timeout => $num\_of\_milliseconds

    Maximum time a command can wait in the local queue before being cancelled with
    "waiting timeout" error. 0 means unlimited (default).

- resume\_waiting\_on\_reconnect => $bool

    Controls behavior of waiting queue on disconnect. If false (default), waiting
    commands are cancelled with error on disconnect. If true, waiting commands are
    preserved and resumed after successful reconnection.

- reconnect => $bool

    Enable automatic reconnection on connection failure or unexpected disconnection.
    Default is disabled (0).

- reconnect\_delay => $num\_of\_milliseconds

    Delay between reconnection attempts. Default is 1000 (1 second).

- max\_reconnect\_attempts => $num

    Maximum number of reconnection attempts. 0 means unlimited. Default is 0.
    Negative values are treated as 0 (unlimited).

- priority => $num

    Priority for the underlying libev IO watchers. Higher priority watchers are
    invoked before lower priority ones. Valid range is -2 (lowest) to +2 (highest),
    with 0 being the default. See [EV](https://metacpan.org/pod/EV) documentation for details on priorities.

- keepalive => $seconds

    Enable TCP keepalive with the specified interval in seconds. When enabled,
    the OS will periodically send probes on idle connections to detect dead peers.
    0 means disabled (default). Recommended for long-lived connections behind
    NAT gateways or firewalls.

- prefer\_ipv4 => $bool

    Prefer IPv4 addresses when resolving hostnames. Mutually exclusive with
    `prefer_ipv6`.

- prefer\_ipv6 => $bool

    Prefer IPv6 addresses when resolving hostnames. Mutually exclusive with
    `prefer_ipv4`.

- source\_addr => 'Str'

    Local address to bind the outbound connection to. Useful on multi-homed
    servers to select a specific network interface.

- tcp\_user\_timeout => $num\_of\_milliseconds

    Set the TCP\_USER\_TIMEOUT socket option (Linux-specific). Controls how long
    transmitted data may remain unacknowledged before the connection is dropped.
    Helps detect dead connections faster on lossy networks.

- cloexec => $bool

    Set SOCK\_CLOEXEC on the Redis connection socket. Prevents the file descriptor
    from leaking to child processes after fork/exec. Default is enabled.

- reuseaddr => $bool

    Set SO\_REUSEADDR on the Redis connection socket. Allows rebinding to an
    address that is still in TIME\_WAIT state. Default is disabled.

- tls => $bool

    Enable TLS/SSL encryption for the connection. Requires that the module was
    built with TLS support (auto-detected at build time, or forced with
    `EV_REDIS_SSL=1`). Only valid with `host` connections, not `path`.

- tls\_ca => 'Str'

    Path to CA certificate file for server verification. If not specified,
    uses the system default CA store.

- tls\_capath => 'Str'

    Path to a directory containing CA certificate files in OpenSSL-compatible
    format (hashed filenames). Alternative to `tls_ca` for multiple CA certs.

- tls\_cert => 'Str'

    Path to client certificate file for mutual TLS authentication. Must be
    specified together with `tls_key`.

- tls\_key => 'Str'

    Path to client private key file. Must be specified together with `tls_cert`.

- tls\_server\_name => 'Str'

    Server name for SNI (Server Name Indication). Optional.

- tls\_verify => $bool

    Enable or disable TLS peer verification. Default is true (verify).
    Set to false to accept self-signed certificates (not recommended for
    production).

- loop => 'EV::Loop',

    EV loop for running this instance. Default is `EV::default_loop`.

All parameters are optional.

If parameters about connection (host&port or path) is not passed, you should call `connect` or `connect_unix` method by hand to connect to redis-server.

## connect($hostname \[, $port\])

## connect\_unix($path)

Connect to a redis-server for `$hostname:$port` or `$path`. `$port`
defaults to 6379. Croaks if a connection is already active.

## command($commands..., \[$cb->($result, $error)\])

Do a redis command and return its result by callback. Returns `REDIS_OK`
(0) on success or `REDIS_ERR` (-1) if the command could not be enqueued
(the error is also delivered via callback, so the return value is rarely needed).

    $redis->command('get', 'foo', sub {
        my ($result, $error) = @_;

        print $result; # value for key 'foo'
        print $error;  # redis error string, undef if no error
    });

If any error is occurred, `$error` presents the error message and `$result` is undef.
If no error, `$error` is undef and `$result` presents response from redis.

The callback is optional. Without a callback, the command runs in
fire-and-forget mode: the reply from Redis is silently discarded and errors
are not reported to Perl code (connection-level errors still trigger
`on_error`). This is useful for high-volume writes where individual
acknowledgement is not needed:

    $redis->set('counter', 42);  # fire-and-forget, no callback

NOTE: Alternatively all commands can be called via AUTOLOAD interface,
including fire-and-forget:

    $redis->command('get', 'foo', sub { ... });

is equivalent to:

    $redis->get('foo', sub { ... });

    $redis->set('counter', 42);  # fire-and-forget via AUTOLOAD

**Note:** Calling `command()` while not connected will croak with
"connection required before calling command", unless automatic reconnection
is active (reconnect timer running). In that case, commands are
automatically queued and sent after successful reconnection. Queued
commands respect `waiting_timeout` if set.

**Pub/Sub note:** For `subscribe`, `psubscribe`, and `ssubscribe`, the
callback is persistent and receives all messages. For `unsubscribe`,
`punsubscribe`, and `sunsubscribe`, the confirmation is delivered through
the original subscribe callback (this is hiredis behavior). Any callback
passed to unsubscribe commands is silently discarded.

## disconnect

Disconnect from redis-server. Safe to call when already disconnected.
Stops any pending reconnect timer, so explicit disconnect prevents automatic
reconnection. Triggers the `on_disconnect` callback when disconnecting
from an active connection. When called while already disconnected, clears
any waiting commands (e.g., preserved by `resume_waiting_on_reconnect`),
invoking their callbacks with a "disconnected" error (`on_disconnect`
does not fire in this case).
This method is usable for exiting event loop.

## is\_connected

Returns true (1) if a connection context is active (including while the
connection is being established), false (0) otherwise.

## has\_ssl

Class method. Returns true (1) if the module was built with TLS support,
false (0) otherwise.

    if (EV::Redis->has_ssl) {
        # TLS connections are available
    }

## connect\_timeout(\[$ms\])

Get or set the connection timeout in milliseconds. Returns the current value,
or undef if not set. Can also be set via constructor.

## command\_timeout(\[$ms\])

Get or set the command timeout in milliseconds. Returns the current value,
or undef if not set. Can also be set via constructor. When changed while
connected, takes effect immediately on the active connection.

## on\_error(\[$cb->($errstr)\])

Set error callback. With a CODE reference argument, replaces the handler
and returns the new handler. With `undef` or without arguments, clears
the handler and returns undef.

**Note:** Calling without arguments clears the handler. There is no way to
read the current handler without clearing it. This applies to all handler
methods (`on_error`, `on_connect`, `on_disconnect`, `on_push`).

## on\_connect(\[$cb->()\])

Set connect callback. With a CODE reference argument, replaces the handler
and returns the new handler. With `undef` or without arguments, clears
the handler and returns undef.

## on\_disconnect(\[$cb->()\])

Set disconnect callback, called on both normal and error disconnections.
With a CODE reference argument, replaces the handler and returns the new
handler. With `undef` or without arguments, clears the handler and
returns undef.

## on\_push(\[$cb->($reply)\])

Set RESP3 push callback for server-initiated messages (Redis 6.0+).
The callback receives the decoded push message as an array reference.
With a CODE reference argument, replaces the handler and returns the new
handler. With `undef` or without arguments, clears the handler and
returns undef. When changed while connected, takes effect immediately.

    $redis->on_push(sub {
        my ($msg) = @_;
        # $msg is an array ref, e.g. ['invalidate', ['key1', 'key2']]
    });

## reconnect($enable, $delay\_ms, $max\_attempts)

Configure automatic reconnection.

    $redis->reconnect(1);                    # enable with defaults (1s delay, unlimited)
    $redis->reconnect(1, 0);                 # enable with immediate reconnect
    $redis->reconnect(1, 2000);              # enable with 2 second delay
    $redis->reconnect(1, 1000, 5);           # enable with 1s delay, max 5 attempts
    $redis->reconnect(0);                    # disable

`$delay_ms` defaults to 1000 (1 second). 0 means immediate reconnect.
`$max_attempts` defaults to 0 (unlimited).

When enabled, the client will automatically attempt to reconnect on connection
failure or unexpected disconnection. Intentional `disconnect()` calls will
not trigger reconnection.

## reconnect\_enabled

Returns true (1) if automatic reconnection is enabled, false (0) otherwise.

## pending\_count

Returns the number of commands sent to Redis awaiting responses.
Persistent commands (subscribe, psubscribe, ssubscribe, monitor) are not
included in this count.
When called from inside a command callback, the count includes the
current command (it is decremented after the callback returns).

## waiting\_count

Returns the number of commands queued locally (not yet sent to Redis).
These are commands that exceeded the `max_pending` limit.

## max\_pending($limit)

Get or set the maximum number of concurrent commands sent to Redis.
Persistent commands (subscribe, psubscribe, ssubscribe, monitor) are not
subject to this limit.
0 means unlimited (default). When the limit is reached, additional commands
are queued locally and sent as responses arrive.

## waiting\_timeout($ms)

Get or set the maximum time in milliseconds a command can wait in the local queue.
Commands exceeding this timeout are cancelled with "waiting timeout" error.
0 means unlimited (default). Returns the current value as an integer (0 when unset).

## resume\_waiting\_on\_reconnect($bool)

Get or set whether waiting commands are preserved on disconnect and resumed
after reconnection. Default is false (waiting commands cancelled on disconnect).

## priority($priority)

Get or set the priority for the underlying libev IO watchers. Higher priority
watchers are invoked before lower priority ones when multiple watchers are
pending. Valid range is -2 (lowest) to +2 (highest), with 0 being the default.
Values outside this range are clamped automatically.
Can be changed at any time, including while connected.

    $redis->priority(1);     # higher priority
    $redis->priority(-1);    # lower priority
    $redis->priority(99);    # clamped to 2
    my $prio = $redis->priority;  # get current priority

## keepalive($seconds)

Get or set the TCP keepalive interval in seconds. When set, the OS sends
periodic probes on idle connections to detect dead peers. 0 means disabled
(default). When set to a positive value while connected, takes effect
immediately. Setting to 0 while connected records the preference for future
connections but does not disable keepalives on the current socket.

## prefer\_ipv4($bool)

Get or set IPv4 preference for DNS resolution. Mutually exclusive with
`prefer_ipv6` (setting one clears the other). Takes effect on the next
connection.

## prefer\_ipv6($bool)

Get or set IPv6 preference for DNS resolution. Mutually exclusive with
`prefer_ipv4` (setting one clears the other). Takes effect on the next
connection.

## source\_addr($addr)

Get or set the local source address to bind to when connecting. This is
useful on multi-homed hosts to control which network interface is used.
Pass `undef` to clear. Takes effect on the next TCP connection (has no
effect on Unix socket connections).

## tcp\_user\_timeout($ms)

Get or set the TCP user timeout in milliseconds. This controls how long
transmitted data may remain unacknowledged before the connection is dropped.
0 means use the OS default. Takes effect on the next connection.

## cloexec($bool)

Get or set the close-on-exec flag for the Redis socket. When enabled, the
socket is automatically closed in child processes after fork+exec. Enabled
by default. Takes effect on the next connection.

## reuseaddr($bool)

Get or set SO\_REUSEADDR on the Redis socket. Allows rebinding to an address
still in TIME\_WAIT state. Disabled by default. Takes effect on the next
connection.

## skip\_waiting

Cancel only waiting (not yet sent) command callbacks. Each callback is invoked
with `(undef, "skipped")`. In-flight commands continue normally.

## skip\_pending

Cancel all pending and waiting command callbacks. Each Perl callback is
invoked immediately with `(undef, "skipped")`. For pending commands,
the internal hiredis tracking entry remains until a reply arrives (which
is then discarded); no second callback fires.

## can($method)

Returns code reference if method is available, undef otherwise.
Methods installed via AUTOLOAD (Redis commands) will return true after first call.

# DESTRUCTION BEHAVIOR

When an EV::Redis object is destroyed (goes out of scope or is explicitly
undefined) while commands are still pending or waiting, hiredis invokes all
pending command callbacks with a disconnect error, and EV::Redis invokes
all waiting queue callbacks with `"disconnected"`. This ensures callbacks
are not orphaned.

For predictable cleanup, explicitly disconnect before destruction:

    $redis->disconnect;    # Clean disconnect, callbacks get error
    undef $redis;          # Safe to destroy

Or use skip methods to cancel with a specific error message:

    $redis->skip_pending;  # Invokes callbacks with (undef, "skipped")
    $redis->skip_waiting;
    $redis->disconnect;
    undef $redis;

**Circular references:** If your callbacks close over the `$redis` variable,
this creates a reference cycle (`$redis` -> object -> callback -> `$redis`)
that prevents garbage collection. Break the cycle before the object goes out
of scope by clearing callbacks:

    $redis->on_error(undef);
    $redis->on_connect(undef);
    $redis->on_disconnect(undef);
    $redis->on_push(undef);

# BENCHMARKS

Measured on Linux with Unix socket connection, 100-byte values, Perl 5.40,
Redis 8.x (`bench/benchmark.pl`):

    Pipeline SET          ~107K ops/sec
    Pipeline GET          ~112K ops/sec
    Mixed workload        ~112K ops/sec
    Fire-and-forget SET   ~655K ops/sec
    Sequential round-trip  ~39K ops/sec (SET+GET pairs)

Fire-and-forget mode (no callback) is roughly 6x faster than callback mode
due to zero Perl-side overhead per command. Pipeline throughput is bounded
by the event loop round-trip, not by hiredis or the network.

Flow control (`max_pending`) has minimal impact at reasonable limits:

    unlimited       ~180K ops/sec
    max_pending=500 ~186K ops/sec
    max_pending=100 ~146K ops/sec

Run `perl bench/benchmark.pl` for full results. Set `BENCH_COMMANDS` and
`BENCH_VALUE_SIZE` environment variables to customize.

# AUTHOR

Daisuke Murase (typester) (original [EV::Hiredis](https://metacpan.org/pod/EV%3A%3AHiredis))

vividsnow

# COPYRIGHT AND LICENSE

Copyright (c) 2013 Daisuke Murase, 2026 vividsnow. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

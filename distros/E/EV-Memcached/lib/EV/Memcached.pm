package EV::Memcached;
use strict;
use warnings;
use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.01';
    XSLoader::load __PACKAGE__, $VERSION;
}

1;

=head1 NAME

EV::Memcached - High-performance asynchronous memcached client using EV

=head1 SYNOPSIS

    use EV::Memcached;

    my $mc = EV::Memcached->new(
        host       => '127.0.0.1',
        port       => 11211,
        on_error   => sub { warn "memcached error: @_" },
        on_connect => sub { warn "connected" },
    );

    $mc->set('foo', 'bar', sub {
        my ($result, $err) = @_;
        die $err if $err;

        $mc->get('foo', sub {
            my ($value, $err) = @_;
            print "foo = $value\n";  # bar
            $mc->disconnect;
        });
    });

    EV::run;

=head1 DESCRIPTION

EV::Memcached is a high-performance asynchronous memcached client that
implements the memcached binary protocol in pure XS with L<EV> event loop
integration. No external C memcached client library is required.

Features:

=over

=item * Binary protocol for efficient encoding and pipelining

=item * Automatic pipelining (multiple commands in flight)

=item * Multi-get optimization via GETKQ + NOOP fence

=item * Flow control (max_pending, waiting queue)

=item * Automatic reconnection

=item * Fire-and-forget mode (no callback)

=item * TCP and Unix socket support

=item * SASL PLAIN authentication (auto-auth on connect)

=item * Connect and command timeouts

=item * Key length validation (250-byte protocol limit)

=back

=head1 ANYEVENT INTEGRATION

L<AnyEvent> has EV as one of its backends, so EV::Memcached can be used
in AnyEvent applications seamlessly.

=head1 NO UTF-8 SUPPORT

This module handles all variables as bytes. Encode your UTF-8 strings
before passing them:

    use Encode;

    $mc->set(foo => encode_utf8($val), sub { ... });

    $mc->get('foo', sub {
        my $val = decode_utf8($_[0]);
    });

=head1 METHODS

=head2 new(%options)

Create a new EV::Memcached instance. All options are optional.

    my $mc = EV::Memcached->new(
        host     => '127.0.0.1',
        port     => 11211,
        on_error => sub { die @_ },
    );

Options:

=over

=item host => 'Str'

=item port => 'Int' (default 11211)

Hostname and port. Mutually exclusive with C<path>.

=item path => 'Str'

Unix socket path. Mutually exclusive with C<host>.

=item on_error => $cb->($errstr)

Error callback for connection-level errors. Default: C<die>.

=item on_connect => $cb->()

Called when connection is established.

=item on_disconnect => $cb->()

Called when disconnected.

=item connect_timeout => $ms

Connection timeout in milliseconds. 0 = no timeout (default).
Only applies to non-blocking TCP connects (not Unix sockets
or immediate localhost connections).

=item command_timeout => $ms

Command timeout in milliseconds. When set, if no response is received
within this interval, the connection is terminated with "command timeout"
error. The timer resets on every response from the server. 0 = no timeout
(default).

=item max_pending => $num

Maximum concurrent commands. 0 = unlimited (default).

=item waiting_timeout => $ms

Max time in local queue before cancellation. 0 = unlimited.

=item resume_waiting_on_reconnect => $bool

Keep waiting queue on disconnect for replay after reconnect.

=item reconnect => $bool

Enable automatic reconnection.

=item reconnect_delay => $ms (default 1000)

=item max_reconnect_attempts => $num (0 = unlimited)

=item priority => $num (-2 to +2)

EV watcher priority.

=item keepalive => $seconds

TCP keepalive interval.

=item username => 'Str'

=item password => 'Str'

SASL PLAIN authentication credentials. When both are set, the client
automatically authenticates after connecting (and after each reconnect).
Requires memcached started with C<-S> flag and SASL support compiled in.

=item loop => EV::Loop

EV loop to use. Default: C<EV::default_loop>.

=back

=head2 connect($host, [$port])

Connect to memcached server. Port defaults to 11211.

=head2 connect_unix($path)

Connect via Unix socket.

=head2 disconnect

Disconnect from server. Stops reconnect timer. Pending command callbacks
receive C<(undef, "disconnected")> error. C<on_disconnect> fires after
pending callbacks have been cancelled.

For intentional disconnect, only C<on_disconnect> fires. For
server-initiated close or errors, C<on_disconnect> fires first, then
C<on_error> fires with the reason (e.g., "connection closed by server",
"command timeout"). This lets you distinguish the two cases.

=head2 is_connected

Returns true if connected or connecting.

=head2 get($key, [$cb->($value, $err)])

Retrieve a value. On miss: C<($value, $err)> are both C<undef>.

=head2 gets($key, [$cb->($result, $err)])

Retrieve with metadata. C<$result> is C<{ value, flags, cas }>.

=head2 set($key, $value, [$expiry, [$flags,]] [$cb])

Store a value. Without callback: fire-and-forget.

=head2 add($key, $value, [$expiry, [$flags,]] [$cb])

Store only if key does not exist.

=head2 replace($key, $value, [$expiry, [$flags,]] [$cb])

Store only if key exists.

=head2 cas($key, $value, $cas, [$expiry, [$flags,]] [$cb])

Compare-and-swap: store only if CAS value matches.

=head2 delete($key, [$cb])

Delete a key.

=head2 incr($key, [$delta, [$initial, [$expiry,]]] [$cb])

Atomic increment. C<$delta> defaults to 1. C<$expiry> defaults to
0xFFFFFFFF (don't create if key doesn't exist).

    $mc->incr('counter', 1, sub {
        my ($new_value, $err) = @_;
    });

    # Auto-create with initial value 100, TTL 300s:
    $mc->incr('counter', 1, 100, 300, sub { ... });

=head2 decr($key, [$delta, [$initial, [$expiry,]]] [$cb])

Atomic decrement. Memcached clamps at 0 (never goes negative).

=head2 append($key, $data, [$cb])

Append data to existing value.

=head2 prepend($key, $data, [$cb])

Prepend data to existing value.

=head2 touch($key, $expiry, [$cb])

Update expiration time without fetching.

=head2 gat($key, $expiry, [$cb->($value, $err)])

Get and touch: retrieve value and update expiration.

=head2 gats($key, $expiry, [$cb->($result, $err)])

Get and touch with metadata.

=head2 mget(\@keys, [$cb->(\%results, $err)])

Multi-get using GETKQ + NOOP fence optimization. Results hash
contains only found keys:

    $mc->mget([qw(k1 k2 k3)], sub {
        my ($results, $err) = @_;
        # $results = { k1 => 'val1', k3 => 'val3' }
        # k2 was a miss (not in hash)
    });

=head2 mgets(\@keys, [$cb->(\%results, $err)])

Like C<mget> but returns full metadata per key:

    $mc->mgets([qw(k1 k2)], sub {
        my ($results, $err) = @_;
        # $results = { k1 => { value => 'v', flags => 0, cas => 123 } }
    });

=head2 version([$cb->($version, $err)])

Get server version string.

=head2 stats([$name,] [$cb->(\%stats, $err)])

Get server statistics. Optional C<$name> for specific stat group.

=head2 flush([$expiry,] [$cb])

Invalidate all items. Optional delay in seconds.

=head2 noop([$cb])

No-operation. Useful as a pipeline fence.

=head2 quit([$cb])

Send quit command. Server will close connection.

=head2 sasl_auth($username, $password, [$cb])

Authenticate using SASL PLAIN mechanism. Called automatically on
connect when C<username> and C<password> constructor options are set.

    $mc->sasl_auth('user', 'secret', sub {
        my ($result, $err) = @_;
        die "auth failed: $err" if $err;
        # authenticated -- proceed with commands
    });

=head2 sasl_list_mechs([$cb->($mechs, $err)])

Query available SASL mechanisms. Returns a space-separated string
(e.g., C<"PLAIN">).

=head2 reconnect($enable, [$delay_ms], [$max_attempts])

Configure automatic reconnection.

=head2 reconnect_enabled

Returns true if reconnect is enabled.

=head2 connect_timeout([$ms])

Get/set connection timeout in milliseconds.

=head2 command_timeout([$ms])

Get/set command timeout in milliseconds. When a response is received,
the timer resets. If no response arrives within the timeout, the
connection is disconnected with "command timeout" error.

=head2 pending_count

Number of commands awaiting server response.

=head2 waiting_count

Number of commands in local queue (flow control).

=head2 max_pending([$limit])

Get/set concurrent command limit.

=head2 waiting_timeout([$ms])

Get/set local queue timeout.

=head2 resume_waiting_on_reconnect([$bool])

Get/set waiting queue behavior on disconnect.

=head2 priority([$num])

Get/set EV watcher priority (-2 to +2).

=head2 keepalive([$seconds])

Get/set TCP keepalive.

=head2 skip_pending

Cancel all pending command callbacks with C<(undef, "skipped")>.

=head2 skip_waiting

Cancel all waiting command callbacks with C<(undef, "skipped")>.

=head2 on_error([$cb])

=head2 on_connect([$cb])

=head2 on_disconnect([$cb])

Get/set handler callbacks.

=head1 DESTRUCTION BEHAVIOR

When an EV::Memcached object is destroyed while commands are still
pending or waiting, all pending callbacks receive C<(undef, "disconnected")>
and all waiting callbacks likewise.

For predictable cleanup:

    $mc->disconnect;
    undef $mc;

Or cancel callbacks first:

    $mc->skip_pending;
    $mc->skip_waiting;
    $mc->disconnect;

B<Circular references:> If callbacks close over C<$mc>, break the cycle
before the object goes out of scope:

    $mc->on_error(undef);
    $mc->on_connect(undef);
    $mc->on_disconnect(undef);

=head1 BENCHMARKS

Measured on Linux with TCP loopback connection, 100-byte values, Perl 5.40,
memcached 1.6.41 (C<bench/benchmark.pl>):

                         50K cmds    200K cmds
    Pipeline SET           213K        68K ops/sec
    Pipeline GET           216K        67K ops/sec
    Mixed workload         226K        69K ops/sec
    Fire-and-forget SET   1.13M      1.29M ops/sec  (SETQ)
    Multi-get (GETKQ)    1.30M       1.17M ops/sec  (per key)
    Sequential round-trip   41K        38K ops/sec

Fire-and-forget mode (no callback) is roughly 5x faster than callback mode
due to zero Perl-side overhead per command. Multi-get is the fastest path
since quiet commands suppress miss responses.

Callback-based throughput scales inversely with batch size because Perl SV
allocation dominates when many closures are queued at once. In real
workloads (commands interleaved with responses), performance stays near
the 50K-column numbers.

Flow control (C<max_pending>) impact (200K commands):

    unlimited       ~131K ops/sec
    max_pending=500 ~126K ops/sec
    max_pending=100 ~120K ops/sec
    max_pending=50  ~117K ops/sec

Run C<perl bench/benchmark.pl> for full results. Set C<BENCH_COMMANDS>,
C<BENCH_VALUE_SIZE>, C<BENCH_HOST>, and C<BENCH_PORT> to customize.

=head1 BINARY PROTOCOL

This module implements the memcached binary protocol directly in XS.
The binary protocol provides efficient encoding with a fixed 24-byte
header, support for pipelining via the opaque field, and quiet command
variants for reduced network traffic.

Multi-get uses the GETKQ (quiet get with key) opcode followed by a
NOOP fence. Only cache hits generate responses; misses are silent.
The NOOP response signals completion of the batch.

Fire-and-forget C<set> uses the SETQ (quiet SET) opcode -- the server
suppresses the response entirely, eliminating network and parsing
overhead. Other commands that can fail (add, replace, delete, incr, etc.)
use normal opcodes even in fire-and-forget mode so error responses are
properly consumed.

Keys are validated against the 250-byte protocol limit.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

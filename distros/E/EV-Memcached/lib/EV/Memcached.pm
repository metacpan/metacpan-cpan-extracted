package EV::Memcached;
use strict;
use warnings;
use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.02';
    XSLoader::load __PACKAGE__, $VERSION;
}

1;

=head1 NAME

EV::Memcached - asynchronous memcached client on libev

=head1 SYNOPSIS

    use EV;
    use EV::Memcached;

    my $mc = EV::Memcached->new(
        host     => '127.0.0.1',
        port     => 11211,
        on_error => sub { warn "memcached: @_" },
    );

    $mc->set('foo', 'bar', sub {
        my ($ok, $err) = @_;
        warn "set failed: $err" if $err;

        $mc->get('foo', sub {
            my ($value, $err) = @_;
            print "foo = $value\n";   # bar
            $mc->disconnect;
        });
    });

    EV::run;

=head1 DESCRIPTION

A pure-XS memcached client built on the L<EV> event loop. Implements the
memcached binary protocol directly -- no external C client library is
needed. All commands are non-blocking; results are delivered through
callbacks dispatched by the EV loop.

Highlights:

=over

=item *

Binary protocol with pipelining, multi-get via GETKQ + NOOP fence, and
fire-and-forget quiet variants (SETQ, FLUSHQ).

=item *

TCP and Unix socket transports, optional SASL PLAIN authentication
(automatic re-auth on reconnect).

=item *

Flow control via C<max_pending>, local C<waiting_queue> with optional
replay across reconnects, configurable connect / command / waiting
timeouts.

=item *

Predictable lifecycle: pending callbacks always fire (with the
disconnect reason on teardown), DESTROY is reentrancy-safe across
callback contexts.

=back

L<AnyEvent> applications can use this module unchanged, since AnyEvent
runs on top of EV when EV is loaded.

=head1 ENCODING

This module treats all keys and values as byte strings. Encode UTF-8
strings before passing them in:

    use Encode;
    $mc->set(foo => encode_utf8($val), sub { ... });
    $mc->get('foo', sub {
        my $val = decode_utf8($_[0]);
    });

=head1 CALLBACK CONVENTIONS

Every command callback receives C<($result, $err)>. On success C<$err>
is C<undef>; on protocol error C<$err> holds a string like C<NOT_STORED>
or C<NOT_FOUND>. On a cache miss for C<get>/C<gat>, B<both> arguments
are C<undef> (a miss is not an error).

Callback exceptions are caught with C<G_EVAL> and reported via C<warn>
so a stray C<die> never unwinds the libev event loop. To abort on
errors, set a flag and break the loop; do not rely on C<die>
propagating out of a callback.

=head1 CONSTRUCTOR

=head2 new(%options)

Construct an instance. All options are optional; with none, the client
is unconfigured and you must call C<connect> / C<connect_unix> later.
Specifying C<host> (or C<path>) at construction time triggers an
immediate non-blocking connect.

    my $mc = EV::Memcached->new(
        host     => '127.0.0.1',
        port     => 11211,
        on_error => sub { warn "@_" },
    );

=head3 Connection

=over

=item host => $str

=item port => $int (default 11211)

TCP host and port. Mutually exclusive with C<path>.

=item path => $str

Unix socket path. Mutually exclusive with C<host>.

=item loop => $ev_loop

EV loop to attach to. Default: C<EV::default_loop>.

=item priority => $num (-2 to +2)

EV watcher priority. Higher = serviced before other EV watchers.

=item keepalive => $seconds

TCP keepalive idle time. Set to 0 to disable. Ignored on Unix sockets.

=back

=head3 Timeouts and flow control

=over

=item connect_timeout => $ms

Abort an in-progress non-blocking connect after this many milliseconds.
0 = no timeout (default). Does not apply to Unix sockets or to
immediately-completing localhost connects.

=item command_timeout => $ms

Disconnect with C<"command timeout"> error if no response arrives
within this interval. The timer resets on every response from the
server. 0 = no timeout (default).

=item max_pending => $num

Cap on concurrent in-flight commands. Excess commands are held in a
local waiting queue. 0 = unlimited (default).

=item waiting_timeout => $ms

Maximum time a command may sit in the waiting queue before its callback
fires with C<"waiting timeout">. 0 = unlimited (default).

=item resume_waiting_on_reconnect => $bool

If true, the waiting queue survives a disconnect and is replayed on
reconnect. Default: false.

=back

=head3 Reconnect

=over

=item reconnect => $bool

Enable automatic reconnection on transport errors.

=item reconnect_delay => $ms (default 1000)

Delay before each reconnect attempt. The delay is always honored via a
timer; setting it to 0 still defers through the event loop (no
synchronous retry recursion).

=item max_reconnect_attempts => $num

Give up after this many consecutive failures and emit
C<"max reconnect attempts reached">. 0 = unlimited (default).

=back

=head3 Authentication

=over

=item username => $str

=item password => $str

SASL PLAIN credentials. When both are set, the client authenticates
after every successful connect (and reconnect). Pre-connect commands
sit in the waiting queue until SASL completes. Requires a memcached
build with SASL support and the C<-S> flag.

=back

=head3 Event handlers

=over

=item on_error => $cb->($errstr)

Connection-level error callback. Default: write the message to
C<STDERR> via C<warn>. Callbacks are run under C<G_EVAL>, so any
C<die> in a custom handler is demoted to a warning -- use an explicit
flag if you need to terminate.

=item on_connect => $cb->()

Fires once the connection is fully established (after SASL, when
applicable).

=item on_disconnect => $cb->()

Fires after a disconnect, after pending callbacks have been cancelled.
For server-initiated close, this fires before C<on_error>.

=back

=head1 LIFECYCLE

=head2 connect($host, [$port])

Connect to a TCP host. Port defaults to 11211. Stops any pending
auto-reconnect timer and clears any prior C<path> setting.

=head2 connect_unix($path)

Connect via Unix domain socket. Stops any pending auto-reconnect timer
and clears any prior C<host> setting.

=head2 disconnect

Disconnect cleanly. Cancels any pending reconnect, drains pending
command callbacks with C<(undef, "disconnected")>, then fires
C<on_disconnect>. For an intentional disconnect, C<on_error> does B<not>
fire -- that distinction lets you tell user-initiated teardown from
server-side close.

=head2 is_connected

Returns true while a session is established B<or> in progress (TCP
handshake / SASL exchange). Commands issued in the connecting phase
are queued and sent on completion.

=head2 quit([$cb])

Send a memcached C<QUIT> and let the server close the connection.

=head1 STORAGE COMMANDS

Each command's callback receives C<($result, $err)>. C<$result> is C<1>
on success.

=head2 set($key, $value, [$expiry, [$flags,]] [$cb])

Store unconditionally. Without C<$cb> this becomes fire-and-forget
(SETQ): no response is received and any server-side failure is silently
dropped.

=head2 add($key, $value, [$expiry, [$flags,]] [$cb])

Store only if the key does not exist. Errors with C<NOT_STORED> if
present.

=head2 replace($key, $value, [$expiry, [$flags,]] [$cb])

Store only if the key already exists. Errors with C<NOT_STORED> if
absent.

=head2 cas($key, $value, $cas, [$expiry, [$flags,]] [$cb])

Compare-and-swap. The C<$cas> token comes from a prior C<gets> /
C<gats> / C<mgets>. Errors with C<EXISTS> on token mismatch or
C<NOT_FOUND> if the key disappeared.

=head2 append($key, $data, [$cb])

Append bytes to an existing value. Errors with C<NOT_STORED> if the
key does not exist. Without C<$cb>, errors are silently dropped.

=head2 prepend($key, $data, [$cb])

Prepend bytes to an existing value. Same error and fire-and-forget
semantics as C<append>.

=head2 delete($key, [$cb])

Delete a key. Errors with C<NOT_FOUND> if absent.

=head1 RETRIEVAL COMMANDS

=head2 get($key, [$cb->($value, $err)])

Retrieve a value. On a cache miss, both C<$value> and C<$err> are
C<undef> -- a miss is not an error.

=head2 gets($key, [$cb->($info, $err)])

Like C<get> but returns C<{ value =E<gt> ..., flags =E<gt> ..., cas =E<gt> ... }>.

=head2 mget(\@keys, [$cb->(\%values, $err)])

Multi-get, internally pipelined as a sequence of GETKQ packets
terminated by a NOOP fence. Returns a hash containing only the keys
that were hits:

    $mc->mget([qw(k1 k2 k3)], sub {
        my ($values, $err) = @_;
        # $values = { k1 => 'v1', k3 => 'v3' }   # k2 was a miss
    });

=head2 mgets(\@keys, [$cb->(\%info, $err)])

Like C<mget> but each value carries metadata:

    $mc->mgets([qw(k1 k2)], sub {
        my ($info, $err) = @_;
        # $info = { k1 => { value => 'v', flags => 0, cas => 123 } }
    });

=head1 ATOMIC COUNTERS

=head2 incr($key, [$delta, [$initial, [$expiry,]]] [$cb->($new_value, $err)])

Atomic increment. C<$delta> defaults to 1. C<$expiry> defaults to
C<0xFFFFFFFF>, which means "do not auto-create" (the call then errors
with C<NOT_FOUND>). Pass any other expiry to auto-create with
C<$initial>:

    $mc->incr('counter', 1, sub { ... });          # require existing
    $mc->incr('counter', 1, 100, 300, sub { ... }); # auto-create at 100, 5min TTL

C<$new_value> is the post-increment counter value.

=head2 decr($key, [$delta, [$initial, [$expiry,]]] [$cb->($new_value, $err)])

Atomic decrement. Memcached clamps the result at 0 (never negative).
Same auto-create semantics as C<incr>.

=head1 EXPIRATION

=head2 touch($key, $expiry, [$cb])

Update an existing key's expiration without fetching the value. Errors
with C<NOT_FOUND> if absent.

=head2 gat($key, $expiry, [$cb->($value, $err)])

Get-and-touch: retrieve and update expiration in one round-trip. Same
miss semantics as C<get>.

=head2 gats($key, $expiry, [$cb->($info, $err)])

Get-and-touch with metadata. Same shape as C<gets>.

=head1 SERVER COMMANDS

=head2 flush([$expiry,] [$cb])

Invalidate every item. Optional delay in seconds before the flush takes
effect. Without C<$cb>, sent as fire-and-forget (FLUSHQ).

=head2 noop([$cb])

No-operation round-trip. Useful as a pipeline fence to wait until all
previously-sent commands have been processed.

=head2 version([$cb->($version, $err)])

Server version string.

=head2 stats([$name,] [$cb->(\%stats, $err)])

Server statistics. Without C<$name>, returns the default stats group.
Common groups: C<settings>, C<items>, C<sizes>, C<slabs>, C<conns>.

=head1 AUTHENTICATION

=head2 sasl_auth($username, $password, [$cb])

Authenticate via SASL PLAIN. Auto-invoked on connect when both
C<username> and C<password> were passed to the constructor; call
manually only when authenticating after a no-auth construction.

=head2 sasl_list_mechs([$cb->($mechs, $err)])

Query the server's supported mechanisms; returns a space-separated
string such as C<"PLAIN">.

=head1 LOCAL CONTROL

=head2 skip_pending

Drain the in-flight queue, firing every callback with
C<(undef, "skipped")>. The connection itself is left intact.

=head2 skip_waiting

Same, but for the local waiting queue (commands not yet sent).

=head2 pending_count

Number of commands sent and awaiting a response.

=head2 waiting_count

Number of commands held in the local waiting queue (because the
connection is not ready, SASL is in progress, or C<max_pending> is
saturated).

=head1 ACCESSORS

Every option from C<new> has a getter/setter of the same name. Calling
without arguments reads the current value; with one argument it writes
and (where meaningful, e.g. C<keepalive>) takes effect immediately.

=over

=item C<connect_timeout([$ms])>

=item C<command_timeout([$ms])>

=item C<max_pending([$num])>

=item C<waiting_timeout([$ms])>

=item C<resume_waiting_on_reconnect([$bool])>

=item C<priority([$num])>

=item C<keepalive([$seconds])>

=item C<reconnect_enabled>

Read-only; configure via C<reconnect>.

=item C<reconnect($enable, [$delay_ms], [$max_attempts])>

Reconfigure auto-reconnect at runtime.

=item C<on_error([$cb])>

=item C<on_connect([$cb])>

=item C<on_disconnect([$cb])>

Get/set the corresponding handler. Pass C<undef> to clear.

=back

=head1 DESTRUCTION

If C<$mc> goes out of scope while commands are in flight or queued,
every pending and waiting callback fires once with
C<(undef, "disconnected")>. This holds whether you call C<disconnect>
first or simply drop the reference.

The clean shutdown idiom is:

    $mc->disconnect;   # drains queues, fires on_disconnect
    undef $mc;

If a callback closes over C<$mc> (a common mistake -- every reference
inside a callback closure keeps the object alive), break the cycle
before dropping the outer reference:

    $mc->on_error(undef);
    $mc->on_connect(undef);
    $mc->on_disconnect(undef);
    undef $mc;

DESTROY is reentrant-safe: if a callback fired during teardown drops
the last external reference to a separate C<EV::Memcached>, that
object's DESTROY is correctly deferred and run once unwound.

=head1 BINARY PROTOCOL NOTES

The wire format is the memcached binary protocol -- a 24-byte header
plus body, with each request tagged by an opaque field used for
in-flight matching and pipelining. Multi-get is sent as a run of
GETKQ packets ending in a NOOP fence: the server emits a response
only on hit, and the NOOP reply terminates the batch. Fire-and-forget
C<set>/C<flush> use the quiet SETQ / FLUSHQ opcodes so the server
sends no response at all.

Commands that can legitimately fail (C<add>, C<replace>, C<delete>,
C<incr>, ...) always use the non-quiet opcode so error responses are
consumed by the client even when the user passed no callback. Keys are
validated against the 250-byte protocol limit before any bytes go on
the wire.

=head1 BENCHMARKS

Numbers from C<bench/benchmark.pl> on Linux, TCP loopback, 100-byte
values, Perl 5.40, memcached 1.6.41:

                         50K cmds    200K cmds
    Pipeline SET           213K        68K ops/sec
    Pipeline GET           216K        67K ops/sec
    Mixed workload         226K        69K ops/sec
    Fire-and-forget SET    1.13M      1.29M ops/sec  (SETQ)
    Multi-get (GETKQ)      1.30M      1.17M ops/sec  (per key)
    Sequential round-trip   41K        38K ops/sec

Fire-and-forget is roughly 5x faster than callback mode because there
is no per-command Perl SV allocation. Multi-get is the fastest read
path since misses generate no traffic. Callback-mode throughput drops
as batch size grows because SV allocation for closures dominates;
realistic workloads (interleaved sends and receives) stay close to the
50K-command column.

C<max_pending> overhead (200K commands):

    unlimited        ~131K ops/sec
    max_pending=500  ~126K ops/sec
    max_pending=100  ~120K ops/sec
    max_pending=50   ~117K ops/sec

Override C<BENCH_COMMANDS>, C<BENCH_VALUE_SIZE>, C<BENCH_HOST>, and
C<BENCH_PORT> to retune.

=head1 SEE ALSO

L<EV>, L<AnyEvent>, L<Cache::Memcached::Fast>, L<Memcached::Client>,
L<https://github.com/memcached/memcached/wiki/BinaryProtocolRevamped>.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

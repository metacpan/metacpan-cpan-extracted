package EV::Redis;
use strict;
use warnings;

use Carp ();
use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.16';
    XSLoader::load __PACKAGE__, $VERSION;
}

my %new_option = map { $_ => 1 } qw(
    host port path loop on_error on_connect on_disconnect on_push
    connect_timeout command_timeout max_pending waiting_timeout
    resume_waiting_on_reconnect priority keepalive prefer_ipv4 prefer_ipv6
    source_addr tcp_user_timeout cloexec reuseaddr reconnect reconnect_delay
    max_reconnect_attempts tls tls_ca tls_capath tls_cert tls_key
    tls_server_name tls_verify
);

sub new {
    my ($class, %args) = @_;

    # a subclass may pass options of its own
    if ((ref $class || $class) eq __PACKAGE__) {
        my @unknown = sort grep { !$new_option{$_} } keys %args;
        Carp::carp("EV::Redis->new: unknown option(s): @unknown") if @unknown;
        Carp::carp("EV::Redis->new: 'port' has no effect without 'host'")
            if defined $args{port} && !exists $args{host};
        if (!$args{tls}) {
            my @tls_only = grep { defined $args{$_} }
                qw(tls_ca tls_capath tls_cert tls_key tls_server_name tls_verify);
            Carp::carp("EV::Redis->new: TLS options (@tls_only) have no effect without 'tls'")
                if @tls_only;
        }
    }

    Carp::croak("Cannot specify both 'host' and 'path'")
        if exists $args{host} && exists $args{path};
    Carp::croak("Cannot specify both 'prefer_ipv4' and 'prefer_ipv6'")
        if $args{prefer_ipv4} && $args{prefer_ipv6};

    my $loop = $args{loop} // EV::default_loop;
    my $self = bless $class->_new($loop), ref $class || $class;

    $self->on_error($args{on_error} // sub { die "$_[0]\n" });
    $self->on_connect($args{on_connect}) if exists $args{on_connect};
    $self->on_disconnect($args{on_disconnect}) if exists $args{on_disconnect};
    $self->on_push($args{on_push}) if exists $args{on_push};
    $self->connect_timeout($args{connect_timeout}) if defined $args{connect_timeout};
    $self->command_timeout($args{command_timeout}) if defined $args{command_timeout};
    $self->max_pending($args{max_pending}) if defined $args{max_pending};
    $self->waiting_timeout($args{waiting_timeout}) if defined $args{waiting_timeout};
    $self->resume_waiting_on_reconnect($args{resume_waiting_on_reconnect}) if defined $args{resume_waiting_on_reconnect};
    $self->priority($args{priority}) if defined $args{priority};
    $self->keepalive($args{keepalive}) if defined $args{keepalive};
    $self->prefer_ipv4($args{prefer_ipv4}) if exists $args{prefer_ipv4};
    $self->prefer_ipv6($args{prefer_ipv6}) if exists $args{prefer_ipv6};
    $self->source_addr($args{source_addr}) if defined $args{source_addr};
    $self->tcp_user_timeout($args{tcp_user_timeout}) if defined $args{tcp_user_timeout};
    $self->cloexec($args{cloexec}) if exists $args{cloexec};
    $self->reuseaddr($args{reuseaddr}) if exists $args{reuseaddr};

    if ($args{reconnect}) {
        $self->reconnect(
            1,
            $args{reconnect_delay} // 1000,
            $args{max_reconnect_attempts} // 0
        );
    }

    # TLS context must be set up before connect
    if ($args{tls}) {
        Carp::croak("TLS support not compiled in; rebuild with EV_REDIS_SSL=1")
            unless $self->has_ssl;
        Carp::croak("TLS requires 'host' parameter (not 'path')")
            if exists $args{path};
        $self->_setup_ssl_context(
            $args{tls_ca}, $args{tls_capath}, $args{tls_cert}, $args{tls_key},
            $args{tls_server_name},
            exists $args{tls_verify} ? ($args{tls_verify} ? 1 : 0) : 1,
        );
    }

    if (exists $args{host}) {
        Carp::croak("'host' must be a defined string") unless defined $args{host};
        defined $args{port}
            ? $self->connect($args{host}, $args{port})
            : $self->connect($args{host});
    }
    elsif (exists $args{path}) {
        Carp::croak("'path' must be a defined string") unless defined $args{path};
        $self->connect_unix($args{path});
    }

    $self;
}

# the XS object is a bare C pointer, meaningless in another interpreter
sub CLONE_SKIP { 1 }

# a thawed copy would carry the same pointer and free it with the original
sub STORABLE_freeze { Carp::croak("EV::Redis objects cannot be serialized") }

# Sereal uses its own hooks; a thawed copy would alias a live object or dangle
sub FREEZE { Carp::croak("EV::Redis objects cannot be serialized") }
sub THAW { Carp::croak("EV::Redis objects cannot be serialized") }

our $AUTOLOAD;

sub AUTOLOAD {
    (my $method = $AUTOLOAD) =~ s/.*:://;
    return if $method eq 'DESTROY';

    my $sub = sub {
        my $self = shift;
        $self->command($method, @_);
    };

    no strict 'refs';
    *$method = $sub;
    goto $sub;
}

1;

=head1 NAME

EV::Redis - Asynchronous redis client using hiredis and EV

=head1 SYNOPSIS

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

=head1 DESCRIPTION

EV::Redis is a fork of L<EV::Hiredis> by Daisuke Murase (typester),
extended with reconnection, flow control, TLS, and RESP3 support. It is a
drop-in replacement for EV::Hiredis, except that commands which would pair
replies with the wrong callbacks croak (see B<Reply order note>).

This is an asynchronous client for Redis using hiredis and L<EV> as backend.
It connects to L<EV> with C-level interface so that it runs faster.

=head1 ANYEVENT INTEGRATION

L<AnyEvent> has a support for EV as its one of backends, so L<EV::Redis> can be used in your AnyEvent applications seamlessly.

=head1 NO UTF-8 SUPPORT

Unlike other redis modules, this module doesn't support utf-8 string.

This module handles all values as bytes: a string with characters above
C<0xFF> croaks with a "Wide character" error. Encode utf-8 strings before
passing them:

    use Encode;
    
    # set $val
    $redis->set(foo => encode_utf8 $val, sub { ... });
    
    # get $val
    $redis->get('foo', sub {
        my $val = decode_utf8 $_[0];
    });

=head1 SIGPIPE

Writing to a connection the server has closed raises C<SIGPIPE>, which
kills the process by default. Set C<$SIG{PIPE} = 'IGNORE'> to get the error
in C<on_error> instead.

=head1 FORK

A child process must not use an inherited object: its connection fails in
the child with "connection inherited from the parent process" (with
C<reconnect>, the child then connects on its own); the parent is not
affected. A loop other than the default needs C<< $loop->loop_fork >> in the
child. Do not fork inside a callback. Objects cannot be copied: C<Storable>
and C<Sereal> with C<freeze_callbacks> croak on them. Other serialized or
C<Clone> copies are inert: their methods croak and destroying them does nothing.

=head1 RESP3 REPLIES

After C<HELLO 3>, maps and sets arrive as array references (a map as a flat
key, value list), doubles as numbers, booleans as 1 or 0, and big numbers and
verbatim strings as plain strings. Attribute replies are not supported: one
ahead of a reply is dropped, one inside an array or map fails the connection.

=head1 METHODS

=head2 new(%options);

Create new L<EV::Redis> instance.

Available C<%options> are:

=over

=item * host => 'Str'

=item * port => 'Int'

Hostname and port number of redis-server to connect. Mutually exclusive with C<path>.

=item * path => 'Str'

UNIX socket path to connect. Mutually exclusive with C<host>.

=item * on_error => $cb->($errstr)

Called on connection-level errors. The default handler dies, but exceptions
thrown in handlers and command callbacks are caught and reported as
warnings, so connection errors become warnings unless you install your own.
C<undef> here keeps the default; C<< on_error(undef) >> removes it.
They never end C<EV::run>, including one from a C<%SIG> handler such as
C<alarm>: use C<command_timeout> or an C<EV::timer> for timeouts.

=item * on_connect => $cb->()

Called when the connection is established (with C<tls>, once TCP is up; a
failed handshake then arrives as C<on_error>).

=item * on_disconnect => $cb->()

Called when the connection closes, normally or on error.

=item * on_push => $cb->($reply)

Called with RESP3 push messages (Redis 6.0+), as an array reference.

The handlers can be set later with the methods of the same name.

=item * connect_timeout => $num_of_milliseconds

Connection timeout.

=item * command_timeout => $num_of_milliseconds

Command timeout.

=item * max_pending => $num

=item * waiting_timeout => $num_of_milliseconds

See the methods of the same name.

=item * resume_waiting_on_reconnect => $bool

If true and C<reconnect> is on, commands waiting locally are kept across a
lost connection and sent after reconnecting. Otherwise (the default) a lost
connection or failed connect attempt cancels them. C<disconnect()>, or giving
up on reconnecting, cancels them either way. A transaction does not survive:
commands issued inside C<WATCH>/C<MULTI>..C<EXEC> are replayed only when none
of the transaction reached the server, and fail with the lost connection
otherwise.

=item * reconnect => $bool

Enable automatic reconnection on connection failure or unexpected disconnection.
Default is disabled (0).

=item * reconnect_delay => $num_of_milliseconds

Delay between reconnection attempts. Default is 1000 (1 second). Used only
with C<reconnect>, as is C<max_reconnect_attempts>.

=item * max_reconnect_attempts => $num

Maximum number of reconnect attempts in a row; an established connection
resets the count. 0 (default) means unlimited.

=item * priority => $num

Priority for the underlying libev IO watchers. Higher priority watchers are
invoked before lower priority ones. Valid range is -2 (lowest) to +2 (highest),
with 0 being the default. See L<EV> documentation for details on priorities.

=item * keepalive => $seconds

Enable TCP keepalive probes on idle connections, with this interval in
seconds (at most 32767; the interval itself is set with glibc and on macOS
only).
0 means disabled (default). Ignored for unix sockets.

=item * prefer_ipv4 => $bool

=item * prefer_ipv6 => $bool

Resolve host names to that address family, falling back to the other only
when the name has no address of it. IPv4 is the default.

=item * source_addr => 'Str'

Local address to bind the outbound connection to. Useful on multi-homed
servers to select a specific network interface. Ignored for unix sockets.

=item * tcp_user_timeout => $num_of_milliseconds

Set TCP_USER_TIMEOUT (Linux): how long sent data may stay unacknowledged
before the connection is dropped. Ignored for unix sockets; where the system
lacks the option, TCP connects fail.

=item * cloexec => $bool

Set close-on-exec on the Redis connection socket. Prevents the file descriptor
from leaking to child processes after fork/exec. Default is enabled.

=item * reuseaddr => $bool

Set SO_REUSEADDR on the Redis connection socket. Allows rebinding to an
address that is still in TIME_WAIT state. Default is disabled. Only takes
effect with C<source_addr>.

=item * tls => $bool

Enable TLS/SSL encryption for the connection. Requires that the module was
built with TLS support (auto-detected at build time, or forced with
C<EV_REDIS_SSL=1>). Only valid with C<host> connections, not C<path>.

=item * tls_ca => 'Str'

Path to CA certificate file for server verification. If not specified,
uses the system default CA store.

=item * tls_capath => 'Str'

Path to a directory containing CA certificate files in OpenSSL-compatible
format (hashed filenames). Alternative to C<tls_ca> for multiple CA certs.

=item * tls_cert => 'Str'

Path to client certificate file for mutual TLS authentication. Must be
specified together with C<tls_key>.

=item * tls_key => 'Str'

Path to client private key file. Must be specified together with C<tls_cert>.

=item * tls_server_name => 'Str'

Server name for SNI, sent on every connection; without it no SNI is sent. It
is not checked against the certificate.

=item * tls_verify => $bool

Verify the server certificate (default true). Only the chain is checked, not
the host name, so use C<tls_ca> with a CA dedicated to your Redis servers
rather than the system store.

=item * loop => 'EV::Loop',

EV loop for running this instance. Default is C<EV::default_loop>.

=back

All parameters are optional. Unknown ones warn, unless C<new> is called
on a subclass.

If parameters about connection (host&port or path) is not passed, you should call C<connect> or C<connect_unix> method by hand to connect to redis-server.

=head2 connect($hostname [, $port])

=head2 connect_unix($path)

Connect to a redis-server for C<$hostname:$port> (default 6379) or C<$path>.
Croaks if a connection is already active or the port or path is invalid. A
failure found at once (a missing socket, a name that does not resolve)
reaches C<on_error> before it returns. Host names are resolved
synchronously, by each reconnect too, outside C<connect_timeout>: pass an IP
address where DNS can be slow.

=head2 command($commands..., [$cb->($result, $error)])

Do a redis command and return its result by callback. Returns C<REDIS_OK>
(0), or C<REDIS_ERR> (-1) if it could not be enqueued (the callback gets the
error too).

    $redis->command('get', 'foo', sub {
        my ($result, $error) = @_;

        print $result; # value for key 'foo'
        print $error;  # redis error string, undef if no error
    });

On error, C<$error> holds the message and C<$result> is undef; otherwise
C<$error> is undef. An error inside an array reply (such as C<EXEC>'s result
for a failed queued command) arrives as its error text.

The callback is optional: only a code reference in the last position is
taken as one, so an C<undef> there is sent as an argument. Without one the
command is fire-and-forget: its reply and errors are discarded (connection
errors still reach C<on_error>):

    $redis->set('counter', 42);  # fire-and-forget, no callback

With a million commands outstanding, a closure per command makes their
completion take minutes; share one code reference instead.

All commands can also be called via the AUTOLOAD interface:

    $redis->command('get', 'foo', sub { ... });

is equivalent to:

    $redis->get('foo', sub { ... });

The Redis C<COMMAND> command itself is reached as
C<< $redis->command('command', ...) >>, since C<command> is this method.

B<Note:> C<command()> croaks with "connection required before calling
command" while not connected, unless a reconnect is pending: commands then
wait locally (see C<resume_waiting_on_reconnect>). In C<on_error> and
C<on_disconnect> it still croaks, as the reconnect is scheduled after they
return. A retry issued from a failed command's callback waits for the
reconnect or fails in turn (after a failed connect with no reconnect
scheduled, it croaks); it never recurses.

B<Pub/Sub note:> C<subscribe> and C<psubscribe> take at least one name and a
persistent callback, which also receives the unsubscribe confirmations (a
callback passed to C<unsubscribe> is ignored unless the command is refused).
Subscribing again to a name moves it to the new callback. An error reply on
a subscribed connection closes it, so keep pub/sub on a connection of its
own; set C<keepalive> to notice a server that vanished, as a subscribed
connection has no timeout. When the connection closes, a subscribe callback
gets one error for each channel or pattern it still holds. Sharded pub/sub (C<ssubscribe>, C<sunsubscribe>)
is not supported and croaks; C<spublish> works.

B<MONITOR note:> C<monitor> requires an idle connection, so it cannot be
issued from within a reply callback; once it is active C<command()> croaks
on that connection. C<pmonitor> is not supported. Use a dedicated one.

B<Reply order note:> hiredis hands each reply to the oldest waiting callback,
so commands that change how the server answers croak: C<CLIENT REPLY OFF>
and C<SKIP>, C<REPLCONF ACK> and C<GETACK>, C<SYNC>, C<PSYNC>, and C<RESET>
while subscribed. Pub/sub commands, C<monitor> and C<HELLO> inside C<MULTI>
fail through their callback; pub/sub and C<HELLO> first wait locally for
outstanding transaction replies, a round trip each. An C<EXEC> cancelled
before it was sent leaves the transaction open.

B<Nested event loop note:> while a callback for an event on this connection
runs, its I/O is paused, so a nested C<EV::run> inside it cannot receive
replies for the same connection. Use a separate connection to wait for
Redis inside a callback.

=head2 disconnect

Disconnect from redis-server; safe when already disconnected. Stops any
pending reconnect and cancels waiting commands with "disconnected" before it
returns. Commands already sent are not cancelled (except on a subscribed
connection): the connection closes once they are answered, then
C<on_disconnect> runs. It runs only for a connection that was established.
So it does not drop a server that stopped answering:
use C<command_timeout>, or destroy the object. Sending C<QUIT> instead is
reported as a lost connection, and C<reconnect> connects again.

=head2 is_connected

Returns true (1) if a connection context is active (including while the
connection is being established), false (0) otherwise.

=head2 has_ssl

Class method. Returns true (1) if the module was built with TLS support,
false (0) otherwise.

    if (EV::Redis->has_ssl) {
        # TLS connections are available
    }

=head2 connect_timeout([$ms])

Get or set the connection timeout in milliseconds (C<0> disables; undef if
never set). It covers the connect attempt after name resolution; with
C<tls>, the TCP connect only (C<command_timeout> ends a stalled handshake
once a command is outstanding). Without it, a unix socket whose server has a
full listen queue is retried in a busy loop.

=head2 command_timeout([$ms])

Get or set the command timeout in milliseconds (C<0> disables; undef if
never set). It fires when replies are outstanding and nothing has arrived
for that long; new commands do not extend it, a large command going out
does. Subscriptions are not covered; an idle MONITOR connection times out.
A command that timed out, or lost its connection, may still have run, or
run later: retry only commands safe to run twice. Changes apply at once.

=head2 on_error([$cb->($errstr)])

Set the error callback. Like all handler methods (C<on_error>,
C<on_connect>, C<on_disconnect>, C<on_push>): a CODE reference replaces the
handler and is returned; C<undef> or no argument clears it (so the current
handler cannot be read); any other value clears it with a warning.

=head2 on_connect([$cb->()])

Set the connect callback. Commands issued from it go first, past
C<max_pending>, so it suits per-connection setup such as C<AUTH> or
C<SELECT>. Commands waiting locally go after that setup; one sent while the
connection was being established goes before it, unless both C<reconnect>
and C<resume_waiting_on_reconnect> are on.

=head2 on_disconnect([$cb->()])

Set the disconnect callback, called on both normal and error disconnections.

=head2 on_push([$cb->($reply)])

Set the RESP3 push callback (Redis 6.0+); it receives the push message as an
array reference.

    $redis->on_push(sub {
        my ($msg) = @_;
        # $msg is an array ref, e.g. ['invalidate', ['key1', 'key2']]
    });

=head2 reconnect($enable, $delay_ms, $max_attempts)

Configure automatic reconnection.

    $redis->reconnect(1);                    # enable with defaults (1s delay, unlimited)
    $redis->reconnect(1, 0);                 # enable with immediate reconnect
    $redis->reconnect(1, 2000);              # enable with 2 second delay
    $redis->reconnect(1, 1000, 5);           # enable with 1s delay, max 5 attempts
    $redis->reconnect(0);                    # disable

C<$delay_ms> defaults to 1000; 0 retries at once, in a busy loop against a
server that refuses connections. C<$max_attempts> defaults to 0 (unlimited).
Explicit undef keeps the current value of that argument.

It reconnects after a failed connect or an unexpected disconnection, not
after C<disconnect()>. A new connection starts fresh: subscriptions,
C<AUTH>, C<SELECT> and C<HELLO> are not restored, so issue them from
C<on_connect>.

=head2 reconnect_enabled

Returns true (1) if automatic reconnection is enabled, false (0) otherwise.

=head2 pending_count

Returns the number of commands sent to Redis awaiting replies, not counting
(p)subscribe, (p)unsubscribe and monitor. Inside a reply callback the count
still includes that command.

=head2 waiting_count

Returns the number of commands queued locally, not yet sent: over
C<max_pending>, during a reconnect, or held for transaction replies, and
those queued behind them.

=head2 max_pending($limit)

Get or set the maximum number of commands sent to Redis at once (0, the
default, means unlimited); further commands wait locally and go out as
replies arrive. (P)subscribe, (p)unsubscribe and monitor hold no slot.

=head2 waiting_timeout($ms)

Get or set the maximum time in milliseconds a command can wait locally
before it fails with "waiting timeout" (0, the default, means unlimited).
Time held only for transaction replies does not count.

=head2 resume_waiting_on_reconnect($bool)

Get or set the option of the same name (see C<new>).

=head2 priority($priority)

Get or set the priority for the underlying libev IO watchers. Higher priority
watchers are invoked before lower priority ones when multiple watchers are
pending. Valid range is -2 (lowest) to +2 (highest), with 0 being the default.
Values outside this range are clamped automatically.
Can be changed at any time, including while connected.

    $redis->priority(1);     # higher priority
    $redis->priority(-1);    # lower priority
    $redis->priority(99);    # clamped to 2
    my $prio = $redis->priority;  # get current priority

=head2 keepalive($seconds)

Get or set the TCP keepalive interval (see C<new>). A positive value set
while connected over TCP applies at once, and croaks if the system refuses
it; 0 applies from the next connection.

=head2 prefer_ipv4($bool)

=head2 prefer_ipv6($bool)

Get or set the address family preference (see C<new>); setting one to a
true value clears the other. Takes effect on the next connection.

=head2 source_addr($addr)

Get or set the local address to bind TCP connections to (C<undef> clears).
Takes effect on the next connection.

=head2 tcp_user_timeout($ms)

=head2 cloexec($bool)

=head2 reuseaddr($bool)

Get or set the option of the same name (see C<new>). Takes effect on the
next connection.

=head2 skip_waiting

Cancel only waiting (not yet sent) command callbacks. Each callback is invoked
with C<(undef, "skipped")>. In-flight commands continue normally. Commands
issued by those callbacks are not cancelled.

=head2 skip_pending

Cancel all pending and waiting command callbacks: each is invoked at once
with C<(undef, "skipped")>, and replies that arrive later are discarded.
Commands issued by those callbacks are not cancelled. On a MONITOR
connection the monitor stream is left running.

=head2 can($method)

Returns a code reference for real methods, and for Redis commands once
they have been called; undef otherwise.

=head1 DESTRUCTION BEHAVIOR

When an EV::Redis object is destroyed with commands still pending or
waiting, their callbacks get C<"disconnected"> (pending ones get the
connection error, if one is in flight). An object still alive at global
destruction (a package variable, or one kept by a reference cycle) runs no callbacks.

B<Circular references:> callbacks that close over C<$redis> form a cycle
that keeps the object alive. Break it by clearing the handlers:

    $redis->on_error(undef);
    $redis->on_connect(undef);
    $redis->on_disconnect(undef);
    $redis->on_push(undef);

=head1 BENCHMARKS

Measured on Linux with Unix socket connection, 100,000 commands with
100-byte values, Perl 5.40, Redis 8.x (C<bench/benchmark.pl> in the source
repository, C<BENCH_COMMANDS=100000>):

    Pipeline SET          ~107K ops/sec
    Pipeline GET          ~112K ops/sec
    Mixed workload        ~112K ops/sec
    Fire-and-forget SET   ~655K ops/sec
    Sequential round-trip  ~39K ops/sec (SET+GET pairs)

Fire-and-forget mode (no callback) is roughly 6x faster than callback mode
due to zero Perl-side overhead per command. Pipeline throughput is bounded
by the event loop round-trip, not by hiredis or the network.

Flow control (C<max_pending>) has minimal impact at reasonable limits:

    unlimited       ~180K ops/sec
    max_pending=500 ~186K ops/sec
    max_pending=100 ~146K ops/sec

Run C<perl bench/benchmark.pl> in a checkout of the repository for full
results. Set C<BENCH_COMMANDS> and C<BENCH_VALUE_SIZE> environment variables
to customize; the default of 10,000 commands gives different rates.

=head1 AUTHOR

Daisuke Murase (typester) (original L<EV::Hiredis>)

vividsnow

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 Daisuke Murase, 2026 vividsnow. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

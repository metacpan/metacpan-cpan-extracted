package EV::Redis;
use strict;
use warnings;

use Carp ();
use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.11';
    XSLoader::load __PACKAGE__, $VERSION;
}

sub new {
    my ($class, %args) = @_;

    Carp::croak("Cannot specify both 'host' and 'path'")
        if exists $args{host} && exists $args{path};
    Carp::croak("Cannot specify both 'prefer_ipv4' and 'prefer_ipv6'")
        if $args{prefer_ipv4} && $args{prefer_ipv6};

    my $loop = $args{loop} // EV::default_loop;
    my $self = $class->_new($loop);

    $self->on_error($args{on_error} // sub { die @_ });
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

    # Configure reconnect if specified
    if ($args{reconnect}) {
        $self->reconnect(
            1,
            $args{reconnect_delay} // 1000,
            $args{max_reconnect_attempts} // 0
        );
    }

    # Configure TLS if specified (must be done before connect)
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
drop-in replacement: the API is fully backward-compatible with EV::Hiredis.

This is an asynchronous client for Redis using hiredis and L<EV> as backend.
It connects to L<EV> with C-level interface so that it runs faster.

=head1 ANYEVENT INTEGRATION

L<AnyEvent> has a support for EV as its one of backends, so L<EV::Redis> can be used in your AnyEvent applications seamlessly.

=head1 NO UTF-8 SUPPORT

Unlike other redis modules, this module doesn't support utf-8 string.

This module handle all variables as bytes. You should encode your utf-8 string before passing commands like following:

    use Encode;
    
    # set $val
    $redis->set(foo => encode_utf8 $val, sub { ... });
    
    # get $val
    $redis->get(foo, sub {
        my $val = decode_utf8 $_[0];
    });

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

Error callback will be called when a connection level error occurs.
If not provided (or C<undef>), a default handler that calls C<die> is
installed. To have no error handler, call C<< $obj->on_error(undef) >>
after construction.

This callback can be set by C<< $obj->on_error($cb) >> method any time.

=item * on_connect => $cb->()

Connection callback will be called when connection successful and completed to redis server.

This callback can be set by C<< $obj->on_connect($cb) >> method any time.

=item * on_disconnect => $cb->()

Disconnect callback will be called when disconnection occurs (both normal and error cases).

This callback can be set by C<< $obj->on_disconnect($cb) >> method any time.

=item * on_push => $cb->($reply)

RESP3 push callback for server-initiated out-of-band messages (Redis 6.0+).
Called with the decoded push message (an array reference). This enables
client-side caching invalidation and other server-push features.

This callback can be set by C<< $obj->on_push($cb) >> method any time.

=item * connect_timeout => $num_of_milliseconds

Connection timeout.

=item * command_timeout => $num_of_milliseconds

Command timeout.

=item * max_pending => $num

Maximum number of commands sent to Redis concurrently. When this limit is reached,
additional commands are queued locally and sent as responses arrive.
0 means unlimited (default). Use C<waiting_count> to check the local queue size.

=item * waiting_timeout => $num_of_milliseconds

Maximum time a command can wait in the local queue before being cancelled with
"waiting timeout" error. 0 means unlimited (default).

=item * resume_waiting_on_reconnect => $bool

Controls behavior of waiting queue on disconnect. If false (default), waiting
commands are cancelled with error on disconnect. If true, waiting commands are
preserved and resumed after successful reconnection.

=item * reconnect => $bool

Enable automatic reconnection on connection failure or unexpected disconnection.
Default is disabled (0).

=item * reconnect_delay => $num_of_milliseconds

Delay between reconnection attempts. Default is 1000 (1 second).

=item * max_reconnect_attempts => $num

Maximum number of reconnection attempts. 0 means unlimited. Default is 0.
Negative values are treated as 0 (unlimited).

=item * priority => $num

Priority for the underlying libev IO watchers. Higher priority watchers are
invoked before lower priority ones. Valid range is -2 (lowest) to +2 (highest),
with 0 being the default. See L<EV> documentation for details on priorities.

=item * keepalive => $seconds

Enable TCP keepalive with the specified interval in seconds. When enabled,
the OS will periodically send probes on idle connections to detect dead peers.
0 means disabled (default). Recommended for long-lived connections behind
NAT gateways or firewalls.

=item * prefer_ipv4 => $bool

Prefer IPv4 addresses when resolving hostnames. Mutually exclusive with
C<prefer_ipv6>.

=item * prefer_ipv6 => $bool

Prefer IPv6 addresses when resolving hostnames. Mutually exclusive with
C<prefer_ipv4>.

=item * source_addr => 'Str'

Local address to bind the outbound connection to. Useful on multi-homed
servers to select a specific network interface.

=item * tcp_user_timeout => $num_of_milliseconds

Set the TCP_USER_TIMEOUT socket option (Linux-specific). Controls how long
transmitted data may remain unacknowledged before the connection is dropped.
Helps detect dead connections faster on lossy networks.

=item * cloexec => $bool

Set SOCK_CLOEXEC on the Redis connection socket. Prevents the file descriptor
from leaking to child processes after fork/exec. Default is enabled.

=item * reuseaddr => $bool

Set SO_REUSEADDR on the Redis connection socket. Allows rebinding to an
address that is still in TIME_WAIT state. Default is disabled.

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

Server name for SNI (Server Name Indication). Optional.

=item * tls_verify => $bool

Enable or disable TLS peer verification. Default is true (verify).
Set to false to accept self-signed certificates (not recommended for
production).

=item * loop => 'EV::Loop',

EV loop for running this instance. Default is C<EV::default_loop>.

=back

All parameters are optional.

If parameters about connection (host&port or path) is not passed, you should call C<connect> or C<connect_unix> method by hand to connect to redis-server.

=head2 connect($hostname [, $port])

=head2 connect_unix($path)

Connect to a redis-server for C<$hostname:$port> or C<$path>. C<$port>
defaults to 6379. Croaks if a connection is already active.

=head2 command($commands..., [$cb->($result, $error)])

Do a redis command and return its result by callback. Returns C<REDIS_OK>
(0) on success or C<REDIS_ERR> (-1) if the command could not be enqueued
(the error is also delivered via callback, so the return value is rarely needed).

    $redis->command('get', 'foo', sub {
        my ($result, $error) = @_;

        print $result; # value for key 'foo'
        print $error;  # redis error string, undef if no error
    });

If any error is occurred, C<$error> presents the error message and C<$result> is undef.
If no error, C<$error> is undef and C<$result> presents response from redis.

The callback is optional. Without a callback, the command runs in
fire-and-forget mode: the reply from Redis is silently discarded and errors
are not reported to Perl code (connection-level errors still trigger
C<on_error>). This is useful for high-volume writes where individual
acknowledgement is not needed:

    $redis->set('counter', 42);  # fire-and-forget, no callback

NOTE: Alternatively all commands can be called via AUTOLOAD interface,
including fire-and-forget:

    $redis->command('get', 'foo', sub { ... });

is equivalent to:

    $redis->get('foo', sub { ... });

B<Note:> Calling C<command()> while not connected will croak with
"connection required before calling command", unless automatic reconnection
is active (reconnect timer running). In that case, commands are
automatically queued and sent after successful reconnection. Queued
commands respect C<waiting_timeout> if set.

B<Pub/Sub note:> For C<subscribe>, C<psubscribe>, and C<ssubscribe>, the
callback is persistent and receives all messages. For C<unsubscribe>,
C<punsubscribe>, and C<sunsubscribe>, the confirmation is delivered through
the original subscribe callback (this is hiredis behavior). Any callback
passed to unsubscribe commands is silently discarded.

=head2 disconnect

Disconnect from redis-server. Safe to call when already disconnected.
Stops any pending reconnect timer, so explicit disconnect prevents automatic
reconnection. Triggers the C<on_disconnect> callback when disconnecting
from an active connection. When called while already disconnected, clears
any waiting commands (e.g., preserved by C<resume_waiting_on_reconnect>),
invoking their callbacks with a "disconnected" error (C<on_disconnect>
does not fire in this case).

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

Get or set the connection timeout in milliseconds. Pass C<0> to disable.
Returns the current value, or undef if never set. Can also be set via
constructor.

=head2 command_timeout([$ms])

Get or set the command timeout in milliseconds. Pass C<0> to disable.
Returns the current value, or undef if never set. Can also be set via
constructor. When changed while connected, takes effect immediately on
the active connection.

=head2 on_error([$cb->($errstr)])

Set error callback. With a CODE reference argument, replaces the handler
and returns the new handler. With C<undef> or without arguments, clears
the handler and returns undef.

B<Note:> Calling without arguments clears the handler. There is no way to
read the current handler without clearing it. This applies to all handler
methods (C<on_error>, C<on_connect>, C<on_disconnect>, C<on_push>).

=head2 on_connect([$cb->()])

Set connect callback. With a CODE reference argument, replaces the handler
and returns the new handler. With C<undef> or without arguments, clears
the handler and returns undef.

=head2 on_disconnect([$cb->()])

Set disconnect callback, called on both normal and error disconnections.
With a CODE reference argument, replaces the handler and returns the new
handler. With C<undef> or without arguments, clears the handler and
returns undef.

=head2 on_push([$cb->($reply)])

Set RESP3 push callback for server-initiated messages (Redis 6.0+).
The callback receives the decoded push message as an array reference.
With a CODE reference argument, replaces the handler and returns the new
handler. With C<undef> or without arguments, clears the handler and
returns undef. When changed while connected, takes effect immediately.

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

C<$delay_ms> defaults to 1000 (1 second). 0 means immediate reconnect.
C<$max_attempts> defaults to 0 (unlimited).

When enabled, the client will automatically attempt to reconnect on connection
failure or unexpected disconnection. Intentional C<disconnect()> calls will
not trigger reconnection.

=head2 reconnect_enabled

Returns true (1) if automatic reconnection is enabled, false (0) otherwise.

=head2 pending_count

Returns the number of commands sent to Redis awaiting responses.
Persistent commands (subscribe, psubscribe, ssubscribe, monitor) are not
included in this count.
When called from inside a command callback, the count includes the
current command (it is decremented after the callback returns).

=head2 waiting_count

Returns the number of commands queued locally (not yet sent to Redis).
These are commands that exceeded the C<max_pending> limit.

=head2 max_pending($limit)

Get or set the maximum number of concurrent commands sent to Redis.
Persistent commands (subscribe, psubscribe, ssubscribe, monitor) are not
subject to this limit.
0 means unlimited (default). When the limit is reached, additional commands
are queued locally and sent as responses arrive.

=head2 waiting_timeout($ms)

Get or set the maximum time in milliseconds a command can wait in the local queue.
Commands exceeding this timeout are cancelled with "waiting timeout" error.
0 means unlimited (default). Returns the current value as an integer (0 when unset).

=head2 resume_waiting_on_reconnect($bool)

Get or set whether waiting commands are preserved on disconnect and resumed
after reconnection. Default is false (waiting commands cancelled on disconnect).

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

Get or set the TCP keepalive interval in seconds. When set, the OS sends
periodic probes on idle connections to detect dead peers. 0 means disabled
(default). When set to a positive value while connected, takes effect
immediately. Setting to 0 while connected records the preference for future
connections but does not disable keepalives on the current socket.

=head2 prefer_ipv4($bool)

Get or set IPv4 preference for DNS resolution. Mutually exclusive with
C<prefer_ipv6> (setting one clears the other). Takes effect on the next
connection.

=head2 prefer_ipv6($bool)

Get or set IPv6 preference for DNS resolution. Mutually exclusive with
C<prefer_ipv4> (setting one clears the other). Takes effect on the next
connection.

=head2 source_addr($addr)

Get or set the local source address to bind to when connecting. This is
useful on multi-homed hosts to control which network interface is used.
Pass C<undef> to clear. Takes effect on the next TCP connection (has no
effect on Unix socket connections).

=head2 tcp_user_timeout($ms)

Get or set the TCP user timeout in milliseconds. This controls how long
transmitted data may remain unacknowledged before the connection is dropped.
0 means use the OS default. Takes effect on the next connection.

=head2 cloexec($bool)

Get or set the close-on-exec flag for the Redis socket. When enabled, the
socket is automatically closed in child processes after fork+exec. Enabled
by default. Takes effect on the next connection.

=head2 reuseaddr($bool)

Get or set SO_REUSEADDR on the Redis socket. Allows rebinding to an address
still in TIME_WAIT state. Disabled by default. Takes effect on the next
connection.

=head2 skip_waiting

Cancel only waiting (not yet sent) command callbacks. Each callback is invoked
with C<(undef, "skipped")>. In-flight commands continue normally.

=head2 skip_pending

Cancel all pending and waiting command callbacks. Each Perl callback is
invoked immediately with C<(undef, "skipped")>. For pending commands,
the internal hiredis tracking entry remains until a reply arrives (which
is then discarded); no second callback fires.

=head2 can($method)

Returns code reference if method is available, undef otherwise.
Methods installed via AUTOLOAD (Redis commands) will return true after first call.

=head1 DESTRUCTION BEHAVIOR

When an EV::Redis object is destroyed (goes out of scope or is explicitly
undefined) while commands are still pending or waiting, hiredis invokes all
pending command callbacks with a disconnect error, and EV::Redis invokes
all waiting queue callbacks with C<"disconnected">. This ensures callbacks
are not orphaned.

For predictable cleanup, explicitly disconnect before destruction:

    $redis->disconnect;    # Clean disconnect, callbacks get error
    undef $redis;          # Safe to destroy

Or use skip methods to cancel with a specific error message:

    $redis->skip_pending;  # Invokes callbacks with (undef, "skipped")
    $redis->skip_waiting;
    $redis->disconnect;
    undef $redis;

B<Circular references:> If your callbacks close over the C<$redis> variable,
this creates a reference cycle (C<$redis> -> object -> callback -> C<$redis>)
that prevents garbage collection. Break the cycle before the object goes out
of scope by clearing callbacks:

    $redis->on_error(undef);
    $redis->on_connect(undef);
    $redis->on_disconnect(undef);
    $redis->on_push(undef);

=head1 BENCHMARKS

Measured on Linux with Unix socket connection, 100-byte values, Perl 5.40,
Redis 8.x (C<bench/benchmark.pl>):

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

Run C<perl bench/benchmark.pl> for full results. Set C<BENCH_COMMANDS> and
C<BENCH_VALUE_SIZE> environment variables to customize.

=head1 AUTHOR

Daisuke Murase (typester) (original L<EV::Hiredis>)

vividsnow

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 Daisuke Murase, 2026 vividsnow. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

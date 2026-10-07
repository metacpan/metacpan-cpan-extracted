package EV::Redis;
use strict;
use warnings;

use Carp ();
use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.15';
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

# the XS object is a bare C pointer; a cloned interpreter would double-free it
sub CLONE_SKIP { 1 }

# a thawed copy would carry the same pointer and free it with the original
sub STORABLE_freeze { Carp::croak("EV::Redis objects cannot be serialized") }

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

This module handle all variables as bytes: command arguments are sent as
their byte representation regardless of Perl's internal string encoding
(upgraded strings are downgraded in place, unless read-only), and passing a string with characters
above C<0xFF> croaks with a "Wide character" error. You should encode your
utf-8 string before passing commands like following:

    use Encode;
    
    # set $val
    $redis->set(foo => encode_utf8 $val, sub { ... });
    
    # get $val
    $redis->get('foo', sub {
        my $val = decode_utf8 $_[0];
    });

=head1 SIGPIPE

Writing to a connection the server has already closed raises C<SIGPIPE>,
which terminates the process by default. Set C<$SIG{PIPE} = 'IGNORE'> so the
write fails instead and the connection error reaches C<on_error> as usual.

=head1 FORK

A child process inherits the connection's socket, which the parent goes on
using. The child never uses it: when the child's loop next has an event
for that connection, the connection fails there with "connection inherited
from the parent process" -- its pending commands get that error, C<on_error>
runs, and C<on_disconnect> too unless it was still connecting, and with
C<reconnect> the child connects on its own. A child forked inside a callback
still gets the replies the parent had already read. A child that exits, or
destroys the object, without running the loop changes nothing. The parent is
not affected. A loop other than the default needs C<< $loop->loop_fork >> in
the child, as L<EV> requires.

Objects cannot be copied: C<Storable> croaks on them, and C<Clone> must not
be used on them: the copy shares the original's connection, and destroying
either one frees it for both.

=head1 RESP3 REPLIES

After C<HELLO 3>, maps and sets arrive as array references (a map as a flat
key, value, key, value list), doubles as numbers, booleans as 1 or 0, and big
numbers and verbatim strings as plain strings, without the verbatim format
tag. Attribute replies are not supported: one ahead of a reply, as
C<DEBUG PROTOCOL attrib> sends, is dropped and the reply arrives as usual;
one inside an array or map, which some modules send, fails the connection
with a protocol error.

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
installed. Note that exceptions thrown inside any handler (including this
default) or command callback are caught and reported as warnings -- they
do not propagate out of the event loop. In practice the default handler
therefore turns connection errors into warnings; install your own
C<on_error> to handle them programmatically. To have no error handler, call
C<< $obj->on_error(undef) >> after construction.

A C<$SIG{__WARN__}> that dies while such a warning is reported cannot stop
the loop either: both messages are printed to STDERR instead. Perl runs a
C<%SIG> handler when Perl code next runs, which inside C<EV::run> is a
callback; a handler that dies there aborts that callback and is reported
as a warning, so an C<alarm> that dies does not end C<EV::run>. Use
C<command_timeout> or an C<EV::timer> instead.

This callback can be set by C<< $obj->on_error($cb) >> method any time.

=item * on_connect => $cb->()

Connection callback will be called when connection successful and completed to redis server.
With C<tls>, it is called once the TCP connection is up; a failed TLS
handshake then arrives as C<on_error> and C<on_disconnect>.

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
commands are cancelled with error on disconnect and on each failed connect
attempt. If true, waiting commands are preserved and resumed after successful
reconnection; an explicit C<disconnect()>, a lost connection or failed
connect without C<reconnect>, or giving up on reconnecting still cancels
them. The settings as the connection is lost decide; a handler changing them
affects the next one, except that C<reconnect(0)> or C<disconnect()> there
cancels the kept commands at once. Commands cancelled on a lost connection
are off the queue before C<on_error> and C<on_disconnect> run.

=item * reconnect => $bool

Enable automatic reconnection on connection failure or unexpected disconnection.
Default is disabled (0).

=item * reconnect_delay => $num_of_milliseconds

Delay between reconnection attempts. Default is 1000 (1 second). Used only
with C<reconnect>, as is C<max_reconnect_attempts>.

=item * max_reconnect_attempts => $num

Maximum number of reconnection attempts. 0 means unlimited. Default is 0.
Negative values are treated as 0 (unlimited). Only connects that fail
count: an established connection starts the count again, also one that is
closed at once or fails its TLS handshake, so retries against such a server
or proxy go on.

=item * priority => $num

Priority for the underlying libev IO watchers. Higher priority watchers are
invoked before lower priority ones. Valid range is -2 (lowest) to +2 (highest),
with 0 being the default. See L<EV> documentation for details on priorities.

=item * keepalive => $seconds

Enable TCP keepalive with the specified interval in seconds (at most 32767).
When enabled, the OS will periodically send probes on idle connections to
detect dead peers. 0 means disabled (default). Recommended for long-lived
connections behind NAT gateways or firewalls. The interval applies on Linux
with glibc and on macOS; elsewhere only keepalive itself is enabled, with the
system's timing. Ignored for unix sockets.

=item * prefer_ipv4 => $bool

Resolve host names to IPv4 addresses, falling back to IPv6 only when there
is none; this is already the default. Mutually exclusive with
C<prefer_ipv6>.

=item * prefer_ipv6 => $bool

Resolve host names to IPv6 addresses, falling back to IPv4 only when there
is none. Mutually exclusive with C<prefer_ipv4>.

=item * source_addr => 'Str'

Local address to bind the outbound connection to. Useful on multi-homed
servers to select a specific network interface.

=item * tcp_user_timeout => $num_of_milliseconds

Set the TCP_USER_TIMEOUT socket option (Linux-specific). Controls how long
transmitted data may remain unacknowledged before the connection is dropped.
Helps detect dead connections faster on lossy networks. Ignored for unix
sockets; where the system lacks the option, TCP connects fail with an error.

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

Server name for SNI (Server Name Indication), sent on every connection the
object makes; without it no SNI is sent, which endpoints that route by SNI
reject. It is not checked against the certificate.

=item * tls_verify => $bool

Enable or disable TLS peer verification. Default is true (verify).
Set to false to accept self-signed certificates (not recommended for
production). Verification checks the certificate chain against the CAs
only: the bundled hiredis does not check that the certificate names the
host, so any certificate those CAs issued is accepted. Use C<tls_ca> with
a CA dedicated to your Redis servers rather than the system store.

=item * loop => 'EV::Loop',

EV loop for running this instance. Default is C<EV::default_loop>.

=back

All parameters are optional. Unknown ones warn, unless C<new> is called
on a subclass.

If parameters about connection (host&port or path) is not passed, you should call C<connect> or C<connect_unix> method by hand to connect to redis-server.

=head2 connect($hostname [, $port])

=head2 connect_unix($path)

Connect to a redis-server for C<$hostname:$port> or C<$path>. C<$port>
defaults to 6379. Croaks if a connection is already active, C<$port> is
outside 1..65535, or C<$path> is too long for a unix socket (over 107 bytes
on Linux, 103 on BSD and macOS).

A failure detected inside the call (a missing unix socket, a host name that
does not resolve) reaches C<on_error> before the method returns, also when
called from C<new>; with reconnect enabled a retry is then scheduled.

The host name is resolved inside the call, and again by each reconnect
attempt: the event loop waits for the system resolver, C<connect_timeout>
does not cover it, and only the first address found is tried. Pass an IP
address where DNS can be slow.

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
An error inside an array reply, such as C<EXEC>'s result for a queued
command that failed, arrives as its error text. Arrays nested more than 512
levels deep in a reply arrive empty; a reply nested more than 1024 levels
deep is a protocol error that closes the connection.

The callback is optional: only a code reference in the last position is
taken as one, so an C<undef> there is sent as an argument. Without a
callback, the command runs in
fire-and-forget mode: the reply from Redis is silently discarded and errors
are not reported to Perl code (connection-level errors still trigger
C<on_error>). This is useful for high-volume writes where individual
acknowledgement is not needed:

    $redis->set('counter', 42);  # fire-and-forget, no callback

The callback is the code reference passed, so reusing a variable for it is
safe. Perl releases many closures in creation order slowly: with a million
commands outstanding, each with a closure of its own, their replies or a
cancel take about two minutes, against under a second with one shared code
reference.

NOTE: Alternatively all commands can be called via AUTOLOAD interface,
including fire-and-forget:

    $redis->command('get', 'foo', sub { ... });

is equivalent to:

    $redis->get('foo', sub { ... });

The Redis C<COMMAND> command itself is reached as
C<< $redis->command('command', ...) >>, since C<command> is this method.

B<Note:> Calling C<command()> while not connected will croak with
"connection required before calling command", unless automatic reconnection
is active (reconnect timer running). Commands issued then wait locally and
are sent in order once a connection is established; with
C<resume_waiting_on_reconnect>, so are commands issued while an attempt is
still connecting. Unless C<resume_waiting_on_reconnect> is set, a failed
attempt cancels waiting commands with its error. Queued commands respect
C<waiting_timeout> if set. A command issued from a command's callback that
reports the loss or timeout of an established connection waits too: with
C<reconnect> and C<resume_waiting_on_reconnect> it is sent on the next
connection, otherwise it fails with that error once C<on_error> and
C<on_disconnect> have run. After a failed connect it croaks as above, unless
a reconnect is scheduled: then it waits for that attempt.
From C<on_error> and C<on_disconnect> themselves it croaks as above: the
reconnect is scheduled only after they return.

B<Pub/Sub note:> For C<subscribe> and C<psubscribe>, the callback is
persistent and receives all messages; at least one channel/pattern argument
is required. For C<unsubscribe> and C<punsubscribe>, the confirmation is
delivered through the original subscribe callback (this is hiredis
behavior). Any callback passed to unsubscribe commands is silently
discarded, unless hiredis refuses the command (as when nothing is
subscribed): then it gets the error. Subscribing again to a channel or pattern that already has a
callback moves it to the new callback, including confirmations still due;
a callback left with no channels is never called again. An error reply
that arrives while the connection is subscribed (RESP2 or RESP3) is taken
by hiredis as a connection error and closes the connection, so keep
pub/sub on a connection of its own. A subscribed connection waits for
messages without a timeout: set C<keepalive> to notice a server that is
gone without closing it. When the connection is lost or C<disconnect()>
closes it, a subscribe callback gets one error for each channel or pattern
it still holds; when the object is destroyed it gets one.

B<Sharded pub/sub note:> C<ssubscribe> and C<sunsubscribe> are not
supported and croak: the bundled hiredis has no sharded pub/sub support, so
it cannot deliver C<smessage> messages to a callback. C<spublish> works as a
regular command.

B<MONITOR note:> C<monitor> requires an idle connection (no pending,
waiting, or subscribed commands), and once active no further commands may
be sent on that connection -- C<command()> croaks. Both restrictions exist
because hiredis's monitor mode re-queues callback records in a way that is
unsafe to mix with other traffic. Use a dedicated connection; the state
clears on disconnect.

B<Reply order note:> hiredis hands each reply to the oldest callback still
waiting for one, so commands that change how the server answers are
refused: C<CLIENT REPLY OFF>, C<CLIENT REPLY SKIP>, C<REPLCONF ACK> and
C<REPLCONF GETACK> croak, and so do C<SYNC> and C<PSYNC>, whose
replication stream is not a sequence of replies; C<RESET> croaks while the connection is
subscribed or a subscribe is waiting (leave with C<unsubscribe> and
C<punsubscribe> and wait for their replies, or disconnect), and fails
through its callback if a subscription was made while it waited; pub/sub
commands, C<monitor> and C<HELLO> sent inside C<MULTI> fail through their
callback. Pub/sub and C<HELLO> wait locally for outstanding transaction
replies before they are checked and sent; each such wait costs a round trip,
and commands issued meanwhile queue behind it. A C<MONITOR> the server refuses
leaves the connection usable. An C<EXEC> cancelled before it is sent (by
C<waiting_timeout> or C<skip_waiting>) leaves the transaction open: later
commands are answered C<QUEUED> until a C<DISCARD>.

B<Nested event loop note:> while a callback runs for an event on this
connection (a reply, message or push, the connect, or the connection's
loss), its I/O watchers are paused, so a nested C<EV::run> (or
condvar-style wait) inside it cannot process replies for the same
connection -- they are delivered after the outer callback returns.
Callbacks of commands cancelled locally (C<waiting_timeout>,
C<skip_waiting>, C<skip_pending>, and waiting commands that C<disconnect()>
cancels) do not pause them. Use a separate connection if you must wait for
Redis inside a callback.

=head2 disconnect

Disconnect from redis-server. Safe to call when already disconnected.
Stops any pending reconnect timer, so explicit disconnect prevents automatic
reconnection. Triggers the C<on_disconnect> callback when disconnecting
from an established connection. Called while the connection is still being
established, it skips C<on_connect> for it; C<on_disconnect> still runs if
commands already sent keep it open until they are answered. Waiting
commands are cancelled with a
"disconnected" error before it returns, also while the connection is still
being established or finishing its pending replies, and when already
disconnected (e.g., commands kept by C<resume_waiting_on_reconnect>).
Commands already sent are not cancelled: the connection closes once their
replies have arrived. That holds while it is still being established too:
they go out when it is up and are answered first. Commands sent while the
connection is subscribed are cancelled with "disconnected" instead. So
C<disconnect()> does not drop a server that stopped answering: use
C<command_timeout>, or destroy the object.

Sending C<QUIT> is no substitute: the server closing the connection is
reported to C<on_error> as a lost connection, and C<reconnect> connects
again.

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
constructor. It counts from the start of the connect attempt, once the host
name is resolved; commands
issued meanwhile do not extend it. Without it, a connect to a unix socket
whose server has a full listen queue is retried in a busy loop until the
server accepts it. With C<tls> it covers the TCP connect only: a stalled
handshake is ended by C<command_timeout>, once a command is outstanding.

=head2 command_timeout([$ms])

Get or set the command timeout in milliseconds. Pass C<0> to disable.
Returns the current value, or undef if never set. Can also be set via
constructor. It fires when replies are outstanding and nothing has been
received for that long; sending more commands does not extend it, but a
command too large for one write counts its bytes going out as progress, as
the system's socket buffer takes them, so a steady stream of such commands
can keep it from firing. That buffer can hold megabytes: on a slow link a
large command can still time out while it goes out.
(P)SUBSCRIBE and (P)UNSUBSCRIBE are not tracked as outstanding replies;
MONITOR is, so a MONITOR connection that sees no traffic for that long is
dropped with a timeout. A command that failed with a timeout, or with a
lost connection, may still have run on the server, or may still run there
later, even after commands sent on the next connection. Repeat only
commands that are safe to run twice.
When changed while connected, takes effect immediately on the active
connection, including re-arming (or stopping, for C<0>) an already-scheduled
timeout for commands currently in flight.

=head2 on_error([$cb->($errstr)])

Set error callback. With a CODE reference argument, replaces the handler
and returns the new handler. With C<undef> or without arguments, clears
the handler and returns undef; any other value clears it with a warning.

B<Note:> Calling without arguments clears the handler. There is no way to
read the current handler without clearing it. This applies to all handler
methods (C<on_error>, C<on_connect>, C<on_disconnect>, C<on_push>).

=head2 on_connect([$cb->()])

Set connect callback. With a CODE reference argument, replaces the handler
and returns the new handler. With C<undef> or without arguments, clears
the handler and returns undef; any other value clears it with a warning.

Commands issued from the callback go ahead of commands waiting in the local
queue and past C<max_pending>, so it suits per-connection setup such as
C<AUTH> or C<SELECT>. If a setup command waits for transaction replies,
later setup commands wait behind it, ahead of the ordinary queue.
Commands still waiting in the local queue when it runs (issued during a
reconnect delay, or over C<max_pending>) go after that setup. One sent while
the connection is being established -- right after C<new> or C<connect>, or
while a reconnect attempt is connecting -- goes ahead of it, unless both
C<reconnect> and C<resume_waiting_on_reconnect> are on, which make it wait.

=head2 on_disconnect([$cb->()])

Set disconnect callback, called on both normal and error disconnections.
With a CODE reference argument, replaces the handler and returns the new
handler. With C<undef> or without arguments, clears the handler and
returns undef; any other value clears it with a warning.

=head2 on_push([$cb->($reply)])

Set RESP3 push callback for server-initiated messages (Redis 6.0+).
The callback receives the decoded push message as an array reference.
With a CODE reference argument, replaces the handler and returns the new
handler. With C<undef> or without arguments, clears the handler and
returns undef; any other value clears it with a warning. When changed
while connected, takes effect immediately.

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

C<$delay_ms> defaults to 1000 (1 second). 0 means immediate reconnect: a
local server that refuses connections then gets tens of thousands of
attempts a second.
C<$max_attempts> defaults to 0 (unlimited).

When enabled, the client will automatically attempt to reconnect on connection
failure or unexpected disconnection. Intentional C<disconnect()> calls will
not trigger reconnection. The reconnect is scheduled after C<on_error> and
C<on_disconnect> return, so C<command()> still croaks inside them. A new
connection starts fresh: subscriptions, C<AUTH>, C<SELECT> and C<HELLO> are
not restored, so issue them from C<on_connect> (which says what can overtake
them).

=head2 reconnect_enabled

Returns true (1) if automatic reconnection is enabled, false (0) otherwise.

=head2 pending_count

Returns the number of commands sent to Redis awaiting responses.
Persistent commands (subscribe, psubscribe, monitor) are not
included in this count.
When called from inside a callback for a reply or a connection error, the
count includes the current command (it is decremented after the callback
returns); inside one that C<skip_pending> runs, it does not.

=head2 waiting_count

Returns the number of commands queued locally (not yet sent to Redis):
commands over the C<max_pending> limit, commands issued while a reconnect
is pending (with C<resume_waiting_on_reconnect>, also while an attempt is
connecting), commands waiting for transaction replies, and later commands
queued behind them to keep their order.

=head2 max_pending($limit)

Get or set the maximum number of concurrent commands sent to Redis.
Persistent commands (subscribe, psubscribe, monitor) do not count toward
the limit; subscribe and psubscribe wait behind it like other commands, and
monitor croaks unless the connection is idle.
0 means unlimited (default). When the limit is reached, additional commands
are queued locally and sent as responses arrive. Replies still owed by a
connection that C<disconnect()> replaced count in C<pending_count> but hold
no slot of the new connection.

=head2 waiting_timeout($ms)

Get or set the maximum time in milliseconds a command can wait in the local queue.
Commands exceeding this timeout are cancelled with "waiting timeout" error.
0 means unlimited (default). Returns the current value as an integer (0 when unset).
With C<reconnect> and C<resume_waiting_on_reconnect> it also covers commands
issued while a connect is in progress. Time spent held only for outstanding
transaction replies (see B<Reply order note>) does not count.

=head2 resume_waiting_on_reconnect($bool)

Get or set whether waiting commands are preserved on disconnect and resumed
after reconnection. Default is false (waiting commands cancelled on disconnect
and on each failed connect attempt).

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

Get or set the TCP keepalive interval in seconds (at most 32767; see the
constructor option for platform limits). When set, the OS sends
periodic probes on idle connections to detect dead peers. 0 means disabled
(default). When set to a positive value while connected over TCP, takes
effect immediately, and croaks, keeping the old value, if the system
refuses it. Setting to 0 while connected records the preference for future
connections but does not disable keepalives on the current socket.

=head2 prefer_ipv4($bool)

Get or set IPv4 preference for DNS resolution, already the default (see
C<new>). Mutually exclusive with
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
0 means use the OS default. Takes effect on the next connection. Applies to
TCP connections only; where the system lacks the option, TCP connects fail
with an error.

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
with C<(undef, "skipped")>. In-flight commands continue normally. Commands
issued by those callbacks are not cancelled.

=head2 skip_pending

Cancel all pending and waiting command callbacks. Each Perl callback is
invoked immediately with C<(undef, "skipped")>. For pending commands,
the internal hiredis tracking entry remains until a reply arrives (which
is then discarded); no second callback fires. Commands issued by those
callbacks, and callbacks already running, are not cancelled.

=head2 can($method)

Returns code reference if method is available, undef otherwise.
Methods installed via AUTOLOAD (Redis commands) will return true after first call.

=head1 DESTRUCTION BEHAVIOR

When an EV::Redis object is destroyed (goes out of scope or is explicitly
undefined) while commands are still pending or waiting, hiredis invokes all
pending command callbacks with a disconnect error, and EV::Redis invokes
all waiting queue callbacks with C<"disconnected">. This ensures callbacks
are not orphaned. An object still alive at global destruction (a package
variable, or one kept by a reference cycle) runs no callbacks.

For predictable cleanup, explicitly disconnect before destruction:

    $redis->disconnect;    # waiting callbacks get "disconnected"
    undef $redis;          # pending callbacks get "disconnected"

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

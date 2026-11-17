package EV::mysql;
use strict;
use warnings;
use Carp ();
use EV ();
use Alien::MySQL ();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('EV::mysql', $VERSION);

my @OPTION_KEYS = qw(
    connect_timeout read_timeout write_timeout
    charset init_command compress multi_statements utf8 found_rows
    ssl_key ssl_cert ssl_ca ssl_capath ssl_cipher
    ssl_verify_server_cert ssl_mode
);

my %ALLOWED_ARGS = map { $_ => 1 } (
    'loop', 'host', 'user', 'password', 'database', 'db', 'port', 'unix_socket',
    'on_connect', 'on_error', @OPTION_KEYS
);

sub new {
    my ($class, %args) = @_;
    for my $k (keys %args) {
        Carp::croak("unknown argument '$k'") unless $ALLOWED_ARGS{$k};
    }

    my $loop = $args{loop} || EV::default_loop();
    my $self = _new($class, $loop);

    for my $k (@OPTION_KEYS) {
        next unless exists $args{$k};
        $self->_set_option($k, $args{$k});
    }

    $self->on_connect($args{on_connect}) if defined $args{on_connect};
    $self->on_error(defined $args{on_error} ? $args{on_error} : sub { die "$_[0]\n" });

    my $database = $args{database} // $args{db};
    if (defined $args{host} || defined $args{unix_socket}) {
        $self->connect(
            $args{host},
            $args{user},
            $args{password},
            $database,
            exists $args{port} ? ($args{port} // 3306) : 3306,
            $args{unix_socket},
        );
    }

    return $self;
}

*reconnect      = \&reset;
*disconnect     = \&finish;
*q              = \&query;
*prep           = \&prepare;
*errstr         = \&error_message;
*error          = \&error_message;
*errno          = \&error_number;
*socket_fd      = \&socket;
*client_version = \&lib_version;
*client_info    = \&lib_info;

sub CLONE_SKIP { 1 }

1;

__END__

=head1 NAME

EV::mysql - Asynchronous MySQL client using libmysqlclient and EV

=head1 SYNOPSIS

    use EV;
    use EV::mysql;

    my $db;
    $db = EV::mysql->new(
        host       => '127.0.0.1',
        port       => 3306,
        user       => 'root',
        password   => '',
        database   => 'test',
        utf8       => 1,
        on_connect => sub { print "connected to ", $db->server_info, "\n" },
        on_error   => sub { die "MySQL connection error: $_[0]\n" },
    );

    $db->query("select 1 + 1 as sum", sub {
        my ($rows, $err, $fields) = @_;
        die "Query failed: $err\n" if $err;
        print "$fields->[0] = $rows->[0][0]\n";
        $db->close_async(sub { EV::break });
    });

    EV::run;

=head1 DESCRIPTION

C<EV::mysql> is an asynchronous, non-blocking Perl client for MySQL built on top
of the L<EV> event loop and Oracle's C<libmysqlclient> (discovered or built via
L<Alien::MySQL>).

Designed as a sibling module to L<EV::MariaDB> with a compatible Perl API, it
allows L<EV>-based applications targeting Oracle MySQL (including MySQL 8.x and
9.x) to execute queued queries, row-by-row streaming queries, transactions, and
prepared statements without blocking the event loop.

=head1 INSTALLATION

Requires C<EV> (E<gt>= 4.11) and C<Alien::MySQL>.

    cpanm EV Alien::MySQL
    perl Makefile.PL
    make
    TEST_MYSQL_HOST=127.0.0.1 TEST_MYSQL_USER=root make test
    make install

Live server tests also accept C<TEST_MYSQL_PORT>, C<TEST_MYSQL_PASS>,
C<TEST_MYSQL_DB>, and C<TEST_MYSQL_SOCKET> (for Unix domain socket connections).

=head1 METHODS

=head2 new(%args)

Creates a new C<EV::mysql> connection handle. If C<host> or C<unix_socket> is
provided, an asynchronous connection is initiated immediately. Croaks on any
unrecognized argument.

Supported arguments:

=over 4

=item * C<loop>

Optional L<EV> loop object (defaults to C<EV::default_loop()>).

=item * C<host>, C<user>, C<password>, C<database> (or C<db>), C<port>, C<unix_socket>

Server connection parameters. C<port> defaults to C<3306>.

=item * C<connect_timeout>, C<read_timeout>, C<write_timeout>

Timeouts in seconds (unsigned integers; C<0> or C<undef> disables the timeout).
C<EV::mysql> enforces these deadlines with event-loop timers on non-blocking
network operations (C<connect>, C<query>, C<query_stream>, and utility ops);
synchronous C<libmysqlclient> operations (see L</NOTES ON LIBMYSQLCLIENT ASYNC API>)
rely on C<libmysqlclient>'s socket-level timeouts.

=item * C<charset>

Client character set (for example C<'utf8mb4'>).

=item * C<init_command>

SQL statement executed automatically upon establishing a connection.

=item * C<utf8>

Boolean; enables Perl UTF-8 decoding for UTF-8 result columns/field names and
UTF-8 encoding for queries, parameters, and C<escape()>.

=item * C<compress>

Boolean; enables MySQL client/server protocol compression.

=item * C<multi_statements>

Boolean; enables semicolon-separated multi-statement queries.

=item * C<found_rows>

Boolean; requests matched-row counts instead of changed-row counts for DML.

=item * C<ssl_key>, C<ssl_cert>, C<ssl_ca>, C<ssl_capath>, C<ssl_cipher>

TLS certificate, key, CA, and cipher suite paths/settings.

=item * C<ssl_verify_server_cert>

Boolean; maps to C<SSL_MODE_VERIFY_IDENTITY> when enabled.

=item * C<ssl_mode>

String SSL mode: C<'DISABLED'>, C<'PREFERRED'>, C<'REQUIRED'>, C<'VERIFY_CA'>,
or C<'VERIFY_IDENTITY'>.

=item * C<on_connect>, C<on_error>

Callbacks invoked with no arguments (C<on_connect>) or C<($err_msg)>
(C<on_error>) on connection completion or connection-level failure. When
C<on_error> is omitted or C<undef> in C<new()>, a default handler that calls
C<die "$_[0]\n"> is installed.

=back

=head2 connect($host, $user, $password, $database, $port, $unix_socket)

Initiates an asynchronous connection on a disconnected handle. Croaks if
already connected or connecting, or if C<$port> is out of range (defaults to
C<3306> when omitted, C<undef>, or C<0>).

=head2 reset()

Resets and reconnects the connection using the previously configured connection
parameters (alias C<reconnect>). Cancels any pending operations and invalidates
outstanding prepared statement handles.

=head2 finish()

Immediately closes the connection, clears pending timeouts/watchers, and
cancels any queued operations with C<"connection finished"> (alias
C<disconnect>). Also invalidates any prepared statement handles.

=head2 close_async($cb)

Drains prior queued operations, sends C<COM_QUIT>, tears down the connection,
and invokes C<$cb-E<gt>(1, undef)>. Rejects subsequent queuing with
C<"connection is closing">; previously prepared statement handles are
no longer valid after C<close_async>.

=head2 on_connect([$handler]), on_error([$handler])

Gets or sets the connection-level callback handlers. Calling with an argument
replaces the current handler (passing C<undef> or a non-CODE value clears it);
calling with no arguments returns the current handler (or C<undef>).

=head2 query($sql, $cb)

Queues an SQL query for asynchronous FIFO execution (alias C<q>). Multiple
queries may be queued while connecting or while a utility op (such as C<ping>,
C<select_db>, C<reset_connection>, C<set_charset>, C<commit>, C<rollback>,
C<autocommit>) is running; croaks C<"cannot queue query while streaming is active">
during C<query_stream>, C<"not connected"> on an uninitialized/disconnected handle,
or C<"connection is closing"> after C<close_async>.

On completion, C<$cb-E<gt>($res, $err, $fields)> is invoked: for result sets
C<$res> is an arrayref of arrayrefs and C<$fields> is an arrayref of column
names; for non-select statements (insert, update, delete, do, etc.) C<$res> is
the integer affected row count. On error C<$res> is C<undef> and C<$err> holds
the error string. When C<multi_statements> is enabled and the first statement
succeeds, secondary statement or drain errors are delivered to C<on_error>.

=head2 query_stream($sql, $row_cb)

Streams result rows one at a time via C<$row_cb-E<gt>($row, $err, $fields)> as
they arrive, invoking C<$row_cb-E<gt>(undef)> at end-of-results (or
C<$row_cb-E<gt>(undef, $err)> on error). Croaks if streaming is already active.
Secondary errors in a C<multi_statements> batch after the first result completes
are delivered to C<on_error>.

=head2 prepare($sql, $cb)

Prepares a server-side statement (alias C<prep>) and invokes
C<$cb-E<gt>($stmt, $err)>. Prepared statement handles are invalidated by
C<close_stmt>, C<finish>, C<reset>, C<reset_connection>, C<change_user>, and
C<close_async>.

=head2 execute($stmt, \@params, $cb) / execute($stmt, $cb)

Executes a prepared statement (snapshotting C<\@params> at queue time, or using
parameters bound via C<bind_params> / C<send_long_data> when C<\@params> is
omitted or C<undef>) and invokes C<$cb-E<gt>($res, $err, $fields)>.

=head2 bind_params($stmt, \@params)

Manually binds parameters on a prepared statement (typically before
C<send_long_data> or C<execute($stmt, undef, $cb)>). Must be called when no
incompatible operation is in progress or queued.

=head2 send_long_data($stmt, $param_idx, $data, $cb)

Sends binary or text parameter chunks for 0-based parameter index C<$param_idx>
before C<execute> and invokes C<$cb-E<gt>($ok, $err)>. Can be called multiple
times per parameter to stream chunks cleanly.

=head2 stmt_reset($stmt, $cb)

Resets a prepared statement handle on the server and invokes
C<$cb-E<gt>($ok, $err)>. Prepared statement handles become invalid after
C<close_stmt>, C<finish>, C<reset>, C<reset_connection>, C<change_user>, or
C<close_async>.

=head2 close_stmt($stmt, $cb)

Closes a prepared statement handle and invokes C<$cb-E<gt>($ok, $err)>. Calling
C<close_stmt>, C<finish>, C<reset>, C<reset_connection>, C<change_user>, or
C<close_async> invalidates outstanding statement handles; closing an
already-invalidated handle invokes C<$cb-E<gt>(1, undef)> immediately.

=head2 ping($cb), select_db($db, $cb), reset_connection($cb)

Asynchronous connection maintenance helpers (utility ops) invoking
C<$cb-E<gt>($ok, $err)>. C<reset_connection> clears server session state and
invalidates outstanding prepared statement handles.

=head2 commit($cb), rollback($cb), autocommit($bool, $cb)

Asynchronous transaction helpers (utility ops) invoking C<$cb-E<gt>($ok, $err)>.
For C<autocommit>, any truthy value enables autocommit and any falsy value
disables it.

=head2 set_charset($charset, $cb), change_user($user, $password, $db, $cb)

Updates the client character set (utility op) or re-authenticates the session
user/database (which also invalidates prepared statements) and invokes
C<$cb-E<gt>($ok, $err)>. Pass C<undef> for C<$db> to keep the current database.

=head2 skip_pending(), pending_count()

C<skip_pending()> cancels queued callbacks with error C<"skipped"> (closing the
wire socket if an in-flight request was already sent). C<pending_count()> returns
the total number of currently active and queued operations.

=head2 escape($str)

Escapes C<$str> for SQL literal interpolation using
C<mysql_real_escape_string>. Requires an active connection.

=head2 is_connected(), is_connecting()

Returns connection state booleans.

=head2 error_message(), error_number(), sqlstate()

Returns the latest error message string (aliases C<error>, C<errstr>), MySQL
error code (alias C<errno>), and 5-character SQLSTATE string.

=head2 affected_rows(), insert_id(), warning_count(), info()

Returns metadata from the most recent completed query or statement (note:
C<insert_id()> returns C<undef> when disconnected).

=head2 thread_id(), host_info(), server_info(), server_version(), character_set_name(), socket()

Returns connection and server metadata (alias C<socket_fd> for C<socket()>).

=head2 EV::mysql-E<gt>lib_version(), EV::mysql-E<gt>lib_info()

Class methods returning the linked C<libmysqlclient> version integer and
informational string (aliases C<client_version>, C<client_info>).

=head1 NOTES ON LIBMYSQLCLIENT ASYNC API

Unlike MariaDB's C<libmariadb>, Oracle's C<libmysqlclient> exports non-blocking
functions exclusively for connection setup, query execution, result retrieval,
row streaming, and connection reset (C<mysql_*_nonblocking>). Functions without
non-blocking equivalents in C<libmysqlclient> (prepared statements, C<set_charset>,
C<change_user>, and C<close_async>) execute against C<libmysqlclient> synchronously
while preserving C<EV::mysql>'s queue, error handling, and asynchronous callback
semantics.

Handles are fork-safe (a forked child automatically detaches the inherited
socket without disturbing the parent connection) and set C<CLONE_SKIP> to C<1>
for Perl ithreads safety.

=head1 EXAMPLES

See the F<eg/> directory included in the distribution:

=over 4

=item * F<eg/basic.pl> - Connecting, creating a temporary table, inserting, selecting, and closing cleanly

=item * F<eg/pipeline.pl> - Pipelined queries and FIFO result ordering

=item * F<eg/prepared.pl> - Prepared statements, parameter binding, NULL values, and cleanup

=item * F<eg/error_handling.pl> - Query errors vs connection errors, recovery, and C<reset_connection>

=back

=head1 SEE ALSO

L<EV>, L<Alien::MySQL>, L<EV::MariaDB>

=head1 AUTHOR

vividsnow

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by vividsnow.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

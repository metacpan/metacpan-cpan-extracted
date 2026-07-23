package EV::MariaDB;
use strict;
use warnings;
use Carp 'croak';

use EV;

BEGIN {
    our $VERSION = '0.08';
    use XSLoader;
    XSLoader::load __PACKAGE__, $VERSION;
}

*q          = \&query;
*prep       = \&prepare;
*reconnect  = \&reset;
*disconnect = \&finish;
*errstr     = \&error_message;
*errno      = \&error_number;

my @OPTION_KEYS = qw(
    connect_timeout read_timeout write_timeout
    compress multi_statements charset init_command
    ssl_key ssl_cert ssl_ca ssl_capath ssl_cipher ssl_verify_server_cert
    utf8 found_rows
);

my %ALLOWED_ARGS = map { $_ => 1 } @OPTION_KEYS, qw(
    loop on_connect on_error
    host user password database db port unix_socket
);

sub CLONE_SKIP { 1 }

sub new {
    my ($class, %args) = @_;

    if (my @unknown = grep !$ALLOWED_ARGS{$_}, keys %args) {
        croak "unknown argument(s) to new(): " . join(', ', sort @unknown);
    }

    my $self = $class->_new($args{loop} || EV::default_loop);

    $self->on_error($args{on_error} || sub { die @_ });
    $self->on_connect($args{on_connect}) if $args{on_connect};

    for my $key (@OPTION_KEYS) {
        $self->_set_option($key, $args{$key}) if defined $args{$key};
    }

    if (defined $args{host} || defined $args{user}) {
        $self->connect(
            $args{host}     // 'localhost',
            $args{user}     // '',
            $args{password} // '',
            ($args{database} // $args{db} // ''),
            $args{port} // 3306,
            $args{unix_socket},
        );
    }

    $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

EV::MariaDB - Async MariaDB/MySQL client using libmariadb and EV

=head1 SYNOPSIS

    use EV;
    use EV::MariaDB;

    my $m = EV::MariaDB->new(
        host       => 'localhost',
        user       => 'root',
        password   => '',
        database   => 'test',
        on_connect => sub { print "connected\n" },
        on_error   => sub { warn "error: $_[0]\n" },
    );

    # simple query (with column metadata)
    $m->query("select * from users", sub {
        my ($rows, $err, $fields) = @_;
        if ($err) { warn $err; return }
        print join(", ", @$fields), "\n";  # column names
        for my $row (@$rows) {
            print join(", ", @$row), "\n";
        }
    });

    # prepared statement
    $m->prepare("select * from users where id = ?", sub {
        my ($stmt, $perr) = @_;
        die $perr if $perr;
        $m->execute($stmt, [42], sub {
            my ($rows, $err) = @_;
            warn $err if $err;
            $m->close_stmt($stmt, sub { });
        });
    });

    # pipelined queries (all sent before reading results)
    for my $id (1..100) {
        $m->q("select * from t where id = $id", sub {
            my ($rows, $err) = @_;
            # callbacks fire in order
        });
    }

    # streaming row-by-row (no full-result buffering)
    $m->query_stream("select * from big_table", sub {
        my ($row, $err) = @_;
        if ($err)          { warn $err; return }
        if (!defined $row) { print "done\n"; return }   # EOF
        # process $row (arrayref)
    });

    EV::run;

=head1 DESCRIPTION

EV::MariaDB is an asynchronous MariaDB/MySQL client that integrates with
the EV event loop. It uses the MariaDB Connector/C non-blocking API to
perform all database operations without blocking the event loop.

Key features:

=over 4

=item * Fully asynchronous connect, query, and prepared statement execution

=item * Query pipelining via C<mysql_send_query>/C<mysql_read_query_result>
for high throughput

=item * Prepared statements with automatic buffer management

=item * Column metadata (field names) returned with query results

=item * Streaming row-by-row results via C<query_stream>

=item * Async transaction control (commit, rollback, autocommit)

=item * Connection utility operations (ping, reset, reset_connection,
change_user, select_db, set_charset)

=item * BLOB/TEXT streaming via C<send_long_data>

=item * Async graceful close via C<close_async>

=item * Multi-result set support for multi-statement queries

=back

=head1 CONSTRUCTOR

=head2 new

    my $m = EV::MariaDB->new(%args);

Creates a new EV::MariaDB object. If C<host> or C<user> is provided,
connects immediately (asynchronously).

B<Connection parameters:>

=over 4

=item host => $hostname

Server hostname. Default: C<localhost>. Note: C<localhost> may connect
via Unix socket; use C<127.0.0.1> to force TCP.

=item port => $port

Server port. Default: C<3306>.

=item user => $username

Username for authentication.

=item password => $password

Password for authentication.

=item database => $dbname

Default database. Also accepts C<db> as an alias.

=item unix_socket => $path

Path to Unix domain socket.

=back

B<Callbacks:>

=over 4

=item on_connect => sub { }

Called once the connection is established. Receives no arguments.

=item on_error => sub { my ($message) = @_ }

Called on connection-level errors (handshake failure, lost connection,
unexpected protocol state). Default: C<sub { die @_ }>.

Exceptions thrown inside either handler are caught and re-emitted as
warnings -- they cannot escape into the event loop.

=back

B<Connection options:>

=over 4

=item connect_timeout => $seconds

=item read_timeout => $seconds

=item write_timeout => $seconds

=item compress => 1

Enable protocol compression.

=item multi_statements => 1

Allow multiple SQL statements per query string. B<Note:> only the first
statement's result set is returned to the callback; secondary result sets
are consumed and discarded. Errors in secondary statements are delivered
via the C<on_error> handler.

=item found_rows => 1

Set the C<CLIENT_FOUND_ROWS> flag. Makes C<UPDATE> return the number of
matched rows instead of changed rows. Useful for upsert patterns where
you need to know if a row existed regardless of whether it was modified.

=item charset => $name

Character set name (e.g., C<utf8mb4>). Controls both result encoding
and how string parameters are interpreted by the server. To round-trip
Perl Unicode strings, set this to C<utf8> or C<utf8mb4> -- see L</UNICODE>.

=item init_command => $sql

SQL statement executed automatically after connecting.

=item ssl_key, ssl_cert, ssl_ca, ssl_capath, ssl_cipher, ssl_verify_server_cert

SSL/TLS connection options. The first five take a string (path or
cipher list); C<ssl_verify_server_cert> takes a boolean. See
L<MYSQL_OPT_SSL_*|https://mariadb.com/docs/connector-c/data-types-and-structures/mysql_optionsv> options
for semantics.

=item utf8 => 1

When enabled, result strings from columns with a UTF-8 charset are
automatically flagged with Perl's internal UTF-8 flag (C<SvUTF8_on>).
Applies to text queries, prepared statements, and streaming results.
Without this option, all result values are returned as raw byte
strings (matching DBD::mysql's default).

Column names in C<$fields> are UTF-8-flagged when the connection
charset is C<utf8> or C<utf8mb4>, regardless of this option.

Requires the connection charset to be C<utf8> or C<utf8mb4> for correct
behaviour. See L</UNICODE>.

=back

B<Event loop:>

=over 4

=item loop => $ev_loop

EV loop to use. Default: C<EV::default_loop>.

=back

=head1 METHODS

All asynchronous methods take a callback as the last argument. The
callback convention is C<($result, $error)>: on success C<$error> is
C<undef>; on failure C<$result> is C<undef> and C<$error> contains the
error message.

Methods divide into two scheduling classes:

=over 4

=item B<Queueable>

C<query> can be called at any time the object is alive -- before connect
completes, while a utility op is running, or while other queries are
already in flight. Calls are pipelined and their callbacks fire in
FIFO order.

=item B<Exclusive>

Every other async method (C<prepare>, C<execute>, C<close_stmt>,
C<stmt_reset>, C<ping>, C<select_db>, C<change_user>,
C<reset_connection>, C<set_charset>, C<commit>, C<rollback>,
C<autocommit>, C<query_stream>, C<close_async>, C<send_long_data>)
requires the connection to be idle. It dies with
C<"cannot start operation while pipeline results are pending"> if any
queued query has not yet delivered its result, or with
C<"another operation is in progress"> if another exclusive op is
running. Schedule these from inside the last queued query's callback,
or after a previous exclusive op completes.

=back

=head2 connect

    $m->connect($host, $user, $password, $database, $port, $unix_socket);

Connects to the server. Called automatically by C<new> when C<host> or
C<user> is provided; use this directly for deferred connection:

    my $m = EV::MariaDB->new(
        on_connect => sub { ... },
        on_error   => sub { ... },
    );
    $m->connect('localhost', 'root', '', 'test', 3306);

C<$port> defaults to C<3306>. C<$password>, C<$database>, and
C<$unix_socket> may be empty strings or C<undef> when not needed.
Dies with C<"already connected"> or C<"connection already in progress">
if invoked twice on the same object.

=head2 query

    $m->query($sql, sub { my ($result, $err, $fields) = @_ });

Executes a SQL query. The callback receives:

=over 4

=item *

For SELECT: C<($rows, undef, $fields)>, where C<$rows> is an arrayref
of row arrayrefs and C<$fields> is an arrayref of column name strings.

=item *

For DML (insert/update/delete): C<($affected_rows, undef)>.

=item *

On error: C<(undef, $error_message)>.

=back

Queries are pipelined (see L</PIPELINING>): consecutive C<query> calls
are dispatched as a batch and their callbacks fire in FIFO order. Safe
to call before C<connect> completes or while an exclusive op
(C<ping>, C<select_db>, ...) is in flight -- the query is buffered
until the connection is idle. Dies with C<"not connected"> if no
connection exists (never connected, or already closed via C<finish>).

By default, result strings are returned as raw bytes. Set
C<< utf8 => 1 >> in the constructor to flag UTF-8 columns automatically;
otherwise decode with L<Encode/decode_utf8>. See L</UNICODE>.

=head2 prepare

    $m->prepare($sql, sub { my ($stmt, $err) = @_ });

Prepares a server-side statement. The callback receives
C<($stmt, undef)> on success or C<(undef, $error)> on failure. Pass
the opaque C<$stmt> handle to C<execute>, C<bind_params>,
C<send_long_data>, C<stmt_reset>, and C<close_stmt>.

A prepared statement is invalidated by C<reset>, C<reset_connection>,
C<change_user>, and C<finish>. Re-prepare after any of these.

=head2 execute

    $m->execute($stmt, \@params, sub { my ($result, $err, $fields) = @_ });

Executes a prepared statement with the given parameters. Parameter
types are detected from the SV: integers bind as C<MYSQL_TYPE_LONGLONG>
(C<BIGINT>) with the unsigned flag tracking C<SvUOK>, floats as
C<MYSQL_TYPE_DOUBLE>, everything else as C<MYSQL_TYPE_STRING>. Pass
C<undef> for C<NULL>. The callback receives results in the same shape
as L</query>.

Pass C<undef> instead of C<\@params> to skip parameter binding and
re-use parameters set by a prior C<bind_params>/C<send_long_data>.

=head2 close_stmt

    $m->close_stmt($stmt, sub { my ($ok, $err) = @_ });

Closes a prepared statement, freeing server and client resources
(including bound parameter buffers). Should be called when the handle
is no longer needed, to free server-side state promptly; otherwise
cleanup happens at object destruction.

Already-invalidated handles (after C<reset>/C<reset_connection>/
C<change_user>) are accepted: the callback fires synchronously with
C<(1, undef)> and the wrapper is freed.

=head2 stmt_reset

    $m->stmt_reset($stmt, sub { my ($ok, $err) = @_ });

Resets a prepared statement (clears errors, unbinds parameters)
without closing it. Croaks
C<"statement handle is no longer valid (connection was reset)"> on a
handle invalidated by C<reset>/C<reset_connection>/C<change_user>.

=head2 ping

    $m->ping(sub { my ($ok, $err) = @_ });

Checks if the connection is alive.

=head2 select_db

    $m->select_db($dbname, sub { my ($ok, $err) = @_ });

Changes the default database. The new name is cached so a subsequent
C<reset> reconnects to it; the cache is rolled back if the operation
fails.

=head2 change_user

    $m->change_user($user, $password, $db_or_undef, sub { my ($ok, $err) = @_ });

Changes the authenticated user and optionally the database. Pass
C<undef> for C<$db> to keep the current database. The new credentials
are cached for C<reset>; the cache is rolled back if the change fails.

B<Note:> The server discards all prepared statements as part of this
operation -- see L</reset_connection> for details.

=head2 reset_connection

    $m->reset_connection(sub { my ($ok, $err) = @_ });

Resets session state (variables, temporary tables, etc.) without
reconnecting. Equivalent to C<COM_RESET_CONNECTION>.

B<Note:> The server discards all prepared statements as part of this
operation. Every statement handle held by Perl code is automatically
marked closed; subsequent C<execute>/C<stmt_reset> calls on those
handles croak C<"statement handle is no longer valid (connection was reset)">.
The same applies to C<change_user>. Re-prepare any statements you need
after the operation completes.

=head2 set_charset

    $m->set_charset($charset, sub { my ($ok, $err) = @_ });

Changes the connection character set asynchronously (e.g.,
C<utf8mb4>). The new charset is cached for C<reset>; the cache is
rolled back if the change fails.

=head2 commit

    $m->commit(sub { my ($ok, $err) = @_ });

Commits the current transaction.

=head2 rollback

    $m->rollback(sub { my ($ok, $err) = @_ });

Rolls back the current transaction.

=head2 autocommit

    $m->autocommit($mode, sub { my ($ok, $err) = @_ });

Enables or disables autocommit mode. C<$mode> is interpreted as a
boolean: any truthy value enables, any falsy value disables.

=head2 query_stream

    $m->query_stream($sql, sub {
        my ($row, $err) = @_;
        if ($err) { warn $err; return }
        if (!defined $row) { print "done\n"; return }
        # process $row (arrayref)
    });

Executes a SELECT query and streams results row-by-row using
C<mysql_use_result>/C<mysql_fetch_row>. The callback is invoked:

=over 4

=item * once per row with C<($row)>, where C<$row> is an arrayref

=item * once at EOF with C<(undef)>

=item * on error with C<(undef, $error_message)>

=back

Unlike C<query>, rows are not buffered -- suitable for very large
result sets. No other queries can be queued while streaming is active.

=head2 close_async

    $m->close_async(sub { my ($ok, $err) = @_ });

Gracefully closes the connection asynchronously (C<COM_QUIT> without
blocking the event loop). C<is_connected> returns false once the
callback has fired. Use C<finish> for an immediate synchronous close.

=head2 send_long_data

    $m->send_long_data($stmt, $param_idx, $data, sub { my ($ok, $err) = @_ });

Sends long parameter data (BLOB/TEXT) for a prepared statement.
C<$param_idx> is zero-based. May be called multiple times for the
same parameter to stream data in chunks. Must be preceded by
C<bind_params> and followed by C<execute> with C<undef> for params:

    $m->prepare("insert into t values (?, ?)", sub {
        my ($stmt) = @_;
        $m->bind_params($stmt, [1, ""]);   # bind all params first
        $m->send_long_data($stmt, 1, $blob_chunk, sub {
            $m->execute($stmt, undef, sub { # undef = keep bound params
                ...
            });
        });
    });

=head2 bind_params

    $m->bind_params($stmt, \@params);

Synchronously binds parameters to a prepared statement without
executing it. Required before C<send_long_data>. Types are detected
the same way as in C<execute>.

Dies with C<"another operation is in progress"> or
C<"cannot bind while pipeline results are pending"> when invoked on a
busy connection.

=head2 reset

    $m->reset;

Disconnects and reconnects using the most recent credentials (as
updated by C<change_user>/C<select_db>/C<set_charset>). Cancels all
pending operations and invalidates every prepared statement handle.
Dies with C<"no previous connection to reset"> if C<connect> has never
been called. Aliased as C<reconnect>.

=head2 finish

    $m->finish;

Closes the connection synchronously and cancels all pending operations
(their callbacks fire with an error). Aliased as C<disconnect>. Use
C<close_async> to close without blocking.

=head2 escape

    my $escaped = $m->escape($string);

Escapes a string for safe interpolation into SQL, respecting the
connection's character set. Warns if the input has Perl's UTF-8 flag
set but the connection charset is not C<utf8>/C<utf8mb4>. Synchronous;
dies with C<"not connected"> if disconnected, or
C<"connection is closing"> while C<close_async> is in flight.

=head2 skip_pending

    $m->skip_pending;

Cancels every pending, queued, and in-flight operation, invoking their
callbacks with C<(undef, "skipped")>. If sent queries are still
awaiting results (or an exclusive op is in flight), the underlying
connection is also closed -- call C<reset> afterwards to reconnect.
Queries that were merely queued are cancelled without disturbing the
connection. When called from within a callback (for example a
C<query_stream> row callback), that same callback is not re-invoked with
the C<"skipped"> error -- you are already inside it.

=head2 on_connect

    $m->on_connect(sub { ... });   # set
    my $cb = $m->on_connect;       # get
    $m->on_connect(undef);         # clear

Accessor for the connect handler. With a CODE ref, replaces the
current handler. With C<undef> (or any non-CODE value), clears it.
With no argument, returns the current handler (or C<undef> if unset).
The handler is fired again after every successful C<reset>/reconnect.

=head2 on_error

    $m->on_error(sub { my ($msg) = @_ });   # set
    my $cb = $m->on_error;                  # get
    $m->on_error(undef);                    # clear

Accessor for the error handler. Same get/set/clear semantics as
C<on_connect>. After clearing, connection-level errors are silently
dropped.

=head1 ACCESSORS

All accessors are synchronous and safe to call at any time; those
that require a live connection return C<undef> (for SV returns) or
C<0>/C<-1> (for numeric returns) when disconnected.

=over 4

=item is_connected

True if a connection is established (and not currently in handshake).

=item error_message

Last error message, or C<undef> when there is none. Aliased as
C<errstr>.

=item error_number

Last error number, or C<0> when there is none. Aliased as C<errno>.

=item sqlstate

SQLSTATE code (5-character string) for the last error. C<"00000">
when there is no error.

=item insert_id

C<AUTO_INCREMENT> value generated by the last insert.

=item affected_rows

Affected rows from the last DML operation. Returns C<undef> on error
or when disconnected. With C<< found_rows => 1 >>, UPDATE returns
matched rows instead of changed rows.

=item warning_count

Number of warnings from the last query.

=item info

Additional info string from the last query (e.g., rows matched for
UPDATE), or C<undef>.

=item server_version

Server version as a packed integer C<MAJOR * 10000 + MINOR * 100 + PATCH>
(e.g., C<110206> for C<11.2.6>).

=item server_info

Server version string.

=item thread_id

Server-side connection (thread) id.

=item host_info

String describing the connection type and host.

=item character_set_name

Current connection character set.

=item socket

File descriptor of the connection socket, or C<-1> when disconnected.

=item pending_count

Number of operations queued or in flight.

=back

=head1 CLASS METHODS

=over 4

=item lib_version

    EV::MariaDB->lib_version;

Client library version as an integer.

=item lib_info

    EV::MariaDB->lib_info;

Client library version string.

=back

=head1 ALIASES

    q          -> query
    prep       -> prepare
    reconnect  -> reset
    disconnect -> finish
    errstr     -> error_message
    errno      -> error_number

=head1 PIPELINING

When multiple queries are submitted before the event loop processes
I/O, EV::MariaDB pipelines them: queries are dispatched to the server
in a single batch, then results are read back in order. This
eliminates per-query round-trip latency and can yield 2-3x higher
throughput than sequential execution.

    # all 100 queries are pipelined
    for (1..100) {
        $m->q("select $_", sub { ... });
    }

Up to 64 queries are kept in flight simultaneously; further queries
queue locally and are dispatched as earlier results drain.

Only C<query> (and its alias C<q>) participates in pipelining.
Prepared statements and utility ops are exclusive (see L</METHODS>).

=head1 UNICODE

EV::MariaDB supports full Unicode (including 4-byte characters such as
emoji) when the connection charset is C<utf8mb4>.

=head2 Setup

    my $m = EV::MariaDB->new(
        charset => 'utf8mb4',
        utf8    => 1,
        ...
    );

C<charset> sets the connection character set used by the server.
C<utf8> controls Perl-side string flagging: when enabled, result
strings from UTF-8 columns are returned with Perl's internal UTF-8
flag set so C<length>, regex, and other character operations behave
correctly.

=head2 Reading

With C<< utf8 => 1 >>, text query, prepared-statement, and streaming
results are UTF-8-flagged per column based on the column's charset.
Binary and non-UTF-8 columns are returned as raw bytes. Column names
in C<$fields> are UTF-8-flagged whenever the connection charset is
C<utf8> or C<utf8mb4>, regardless of this option.

Without C<< utf8 => 1 >>, all values are byte strings -- decode with
L<Encode/decode_utf8>.

=head2 Writing

No special handling is needed. Perl strings (UTF-8-flagged or not) are
sent as their underlying byte representation via C<SvPV>. As long as
the connection charset matches the encoding of the bytes (i.e.,
C<< charset => 'utf8mb4' >> for UTF-8 data), the server stores them
correctly. This applies to both text queries (C<query>, C<escape>) and
prepared-statement parameters (C<execute>, C<bind_params>).

=head1 CAVEATS

EV::MariaDB uses process-global freelists and is B<not> safe for concurrent
use from multiple ithreads. Use one interpreter thread, or a separate
process per thread.

=head1 SEE ALSO

L<EV>, L<Alien::MariaDB>, L<DBD::MariaDB>, L<AnyEvent::MySQL>.
MariaDB Connector/C non-blocking API:
L<https://mariadb.com/docs/connector-c/api-functions/non-blocking>.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

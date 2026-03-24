package EV::MariaDB;
use strict;
use warnings;
use Carp 'croak';

use EV;

BEGIN {
    our $VERSION = '0.04';
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

sub CLONE_SKIP { 1 }

sub new {
    my ($class, %args) = @_;

    my $loop = delete $args{loop} || EV::default_loop;
    my $self = $class->_new($loop);

    $self->on_error(delete $args{on_error} || sub { die @_ });
    if (my $cb = delete $args{on_connect}) {
        $self->on_connect($cb);
    }

    # set connection options before connect
    for my $key (@OPTION_KEYS) {
        if (defined(my $val = delete $args{$key})) {
            $self->_set_option($key, $val);
        }
    }

    my $host     = delete $args{host};
    my $user     = delete $args{user};
    my $password = delete $args{password};
    my $database = delete $args{database} // delete $args{db};
    my $port     = delete $args{port} // 3306;
    my $socket   = delete $args{unix_socket};

    if (my @unknown = keys %args) {
        croak "unknown argument(s) to new(): " . join(', ', sort @unknown);
    }

    if (defined $host || defined $user) {
        $self->connect(
            $host     // 'localhost',
            $user     // '',
            $password // '',
            $database // '',
            $port,
            $socket,
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
        my ($stmt, $err) = @_;
        die $err if $err;
        $m->execute($stmt, [42], sub {
            my ($rows, $err, $fields) = @_;
            # ...
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

=item * Connection utility operations (ping, reset, change_user, select_db, set_charset)

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

Called when the connection is established. No arguments.
Exceptions thrown inside this handler are caught and re-emitted
as warnings to protect the event loop.

=item on_error => sub { my ($message) = @_ }

Called on connection-level errors. Default: C<sub { die @_ }>.
Note: exceptions thrown inside this handler are caught and re-emitted
as warnings to protect the event loop.

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

Character set name (e.g., C<utf8mb4>). This controls both result encoding
and how string parameters are interpreted by the server. If you bind
Perl Unicode strings (with the UTF-8 flag) to prepared statements, the
connection charset B<must> be set to C<utf8> or C<utf8mb4> — otherwise
the raw UTF-8 bytes are sent without transcoding and may be misinterpreted.

=item init_command => $sql

SQL statement executed automatically after connecting.

=item ssl_key => $path

=item ssl_cert => $path

=item ssl_ca => $path

=item ssl_capath => $path

=item ssl_cipher => $list

=item ssl_verify_server_cert => 1

SSL/TLS connection options.

=item utf8 => 1

When enabled, result strings from columns with a UTF-8 charset are
automatically flagged with Perl's internal UTF-8 flag (C<SvUTF8_on>).
This applies to text queries, prepared statements, and streaming results.
Column names in C<$fields> are UTF-8-flagged when the connection charset
is C<utf8> or C<utf8mb4>, regardless of this option. Without this option,
all result values are returned as raw byte
strings (the default, matching DBD::mysql behavior).

Requires the connection charset to be C<utf8> or C<utf8mb4> for correct
behavior.

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

=head2 connect

    $m->connect($host, $user, $password, $database, $port, $unix_socket);

Connects to the server. Called automatically by C<new> when C<host> or
C<user> is provided. Use this for deferred connection:

    my $m = EV::MariaDB->new(
        on_connect => sub { ... },
        on_error   => sub { ... },
    );
    $m->connect('localhost', 'root', '', 'test', 3306);

Dies if a connection is in progress or already established. C<$port> defaults to 3306. C<$unix_socket>
is optional (pass C<undef> or omit).

=head2 query

    $m->query($sql, sub { my ($result, $err, $fields) = @_ });

Executes a SQL query. The callback receives:

=over 4

=item * For select: C<($arrayref_of_arrayrefs, undef, $field_names)>

C<$field_names> is an arrayref of column name strings.

=item * For DML (insert/update/delete): C<($affected_rows, undef)>

=item * On error: C<(undef, $error_message)>

=back

Queries are pipelined: multiple calls to C<query> before the event loop
runs will be sent as a batch, with results read back in order. May be
called after C<connect> has been initiated (even before it completes);
queries are buffered and sent once connected. Also safe to call while a
utility operation (C<ping>, C<select_db>, etc.) is active - the query
is buffered and executed when the operation completes. Dies if
C<connect> has not been called at all.

B<Note:> By default, result strings are returned as byte strings without
Perl's internal UTF-8 flag. Set C<< utf8 => 1 >> in the constructor to
automatically flag UTF-8 results, or use C<Encode::decode_utf8> manually.

=head2 prepare

    $m->prepare($sql, sub { my ($stmt, $err) = @_ });

Prepares a server-side statement. The callback receives an opaque
statement handle or an error. Pass the handle to C<execute>,
C<close_stmt>, and C<stmt_reset>.

=head2 execute

    $m->execute($stmt, \@params, sub { my ($result, $err, $fields) = @_ });

Executes a prepared statement with the given parameters. Parameters are
type-detected: integers bind as C<BIGINT> (unsigned integers are flagged
accordingly), floats as C<DOUBLE>, all others as C<STRING>. Pass
C<undef> for C<NULL>. The callback receives results in the same format
as C<query> (including C<$fields> for SELECT results).

Pass C<undef> instead of C<\@params> to skip parameter binding and use
previously bound parameters (see C<bind_params> and C<send_long_data>).

=head2 close_stmt

    $m->close_stmt($stmt, sub { my ($ok, $err) = @_ });

Closes a prepared statement, freeing server and client resources
(including bound parameter buffers). B<Must> be called for every
prepared statement to avoid memory leaks.

=head2 stmt_reset

    $m->stmt_reset($stmt, sub { my ($ok, $err) = @_ });

Resets a prepared statement (clears errors and unbinds parameters)
without closing it.

=head2 ping

    $m->ping(sub { my ($ok, $err) = @_ });

Checks if the connection is alive.

=head2 select_db

    $m->select_db($dbname, sub { my ($ok, $err) = @_ });

Changes the default database.

=head2 change_user

    $m->change_user($user, $password, $db_or_undef, sub { my ($ok, $err) = @_ });

Changes the user and optionally the database. Pass C<undef> for C<$db>
to keep the current database.

=head2 reset_connection

    $m->reset_connection(sub { my ($ok, $err) = @_ });

Resets session state (variables, temporary tables, etc.) without
reconnecting. Equivalent to C<COM_RESET_CONNECTION>.

=head2 set_charset

    $m->set_charset($charset, sub { my ($ok, $err) = @_ });

Changes the connection character set asynchronously (e.g., C<utf8mb4>).

=head2 commit

    $m->commit(sub { my ($ok, $err) = @_ });

Commits the current transaction.

=head2 rollback

    $m->rollback(sub { my ($ok, $err) = @_ });

Rolls back the current transaction.

=head2 autocommit

    $m->autocommit($mode, sub { my ($ok, $err) = @_ });

Enables (C<$mode = 1>) or disables (C<$mode = 0>) autocommit mode.

=head2 query_stream

    $m->query_stream($sql, sub {
        my ($row, $err) = @_;
        if ($err) { warn $err; return }
        if (!defined $row) { print "done\n"; return }
        # process $row (arrayref)
    });

Executes a SELECT query and streams results row-by-row using
C<mysql_use_result>/C<mysql_fetch_row>. The callback is invoked once
per row with C<($arrayref)>, once at EOF with C<(undef)>, or on error
with C<(undef, $error_message)>. Unlike C<query>, results are not
buffered in memory - suitable for large result sets.

This is an exclusive operation: no other queries can be queued while
streaming is active.

=head2 close_async

    $m->close_async(sub { my ($ok, $err) = @_ });

Gracefully closes the connection asynchronously (sends C<COM_QUIT>
without blocking the event loop). After completion, C<is_connected>
returns false. Use C<finish> for immediate synchronous close.

=head2 send_long_data

    $m->send_long_data($stmt, $param_idx, $data, sub { my ($ok, $err) = @_ });

Sends long parameter data (BLOB/TEXT) for a prepared statement.
Can be called multiple times for the same parameter to send data
in chunks. Must be called after C<bind_params> and before C<execute>.

Typical workflow:

    $m->prepare("insert into t values (?, ?)", sub {
        my ($stmt) = @_;
        $m->bind_params($stmt, [1, ""]);  # bind all params first
        $m->send_long_data($stmt, 1, $blob_data, sub {
            $m->execute($stmt, undef, sub {  # undef = skip re-binding
                # ...
            });
        });
    });

=head2 bind_params

    $m->bind_params($stmt, \@params);

Synchronously binds parameters to a prepared statement without
executing it. Required before C<send_long_data>. Parameter types are
auto-detected the same way as in C<execute>.

=head2 reset

    $m->reset;

Disconnects and reconnects using the original connection parameters.
Cancels all pending operations. Dies if no prior connection exists.

=head2 finish

    $m->finish;

Disconnects from the server. Cancels all pending operations, invoking
their callbacks with an error.

=head2 escape

    my $escaped = $m->escape($string);

Escapes a string for safe use in SQL, respecting the connection's
character set. Warns if the string has Perl's UTF-8 flag set but the
connection charset is not C<utf8>/C<utf8mb4>.

=head2 skip_pending

    $m->skip_pending;

Cancels all pending, queued, and in-flight operations, invoking their
callbacks with C<(undef, "skipped")>. If an async operation is active or
sent queries are awaiting results, the connection is closed (use
C<reset> to reconnect). Queued but unsent queries are cancelled without
closing the connection.

=head2 on_connect

    $m->on_connect(sub { ... });   # set handler
    my $cb = $m->on_connect;       # get handler

Get or set the connect handler. When called with a CODE reference,
sets the handler. When called without arguments, returns the current
handler (or C<undef> if unset).

=head2 on_error

    $m->on_error(sub { my ($msg) = @_ });   # set handler
    my $cb = $m->on_error;                  # get handler

Get or set the error handler. When called with a CODE reference,
sets the handler. When called without arguments, returns the current
handler (or C<undef> if unset).

=head1 ACCESSORS

=over 4

=item is_connected

Returns true if connected to the server.

=item error_message

Last error message, or C<undef>.

=item error_number

Last error number (0 if no error).

=item sqlstate

SQLSTATE code (5-character string) for the last error.

=item insert_id

Auto_increment value from the last insert.

=item affected_rows

Number of affected rows from the last DML operation, or C<undef> on
error. With C<< found_rows => 1 >>, UPDATE returns matched rows instead.

=item warning_count

Number of warnings from the last query.

=item info

Additional info about the last query (e.g., rows matched for update),
or C<undef>.

=item server_version

Server version as an integer (e.g., 110206 for 11.2.6).

=item server_info

Server version string.

=item thread_id

Connection thread ID.

=item host_info

String describing connection type and host.

=item character_set_name

Current character set name.

=item socket

File descriptor of the connection socket.

=item pending_count

Number of pending operations (queued + in-flight).

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

When multiple queries are submitted before the event loop processes I/O,
EV::MariaDB pipelines them: all queries are sent to the server before
reading any results. This reduces round-trip overhead and can achieve
2-3x higher throughput than sequential execution.

    # all 100 queries are pipelined
    for (1..100) {
        $m->q("select $_", sub { ... });
    }

The maximum pipeline depth is 64 queries. Additional queries are buffered
and sent as earlier results are received.

=head1 UNICODE

EV::MariaDB supports full Unicode (including 4-byte characters like emoji)
when the connection charset is C<utf8mb4>.

=head2 Setup

    my $m = EV::MariaDB->new(
        charset => 'utf8mb4',
        utf8    => 1,
        ...
    );

The C<charset> option sets the connection character set used by the server.
The C<utf8> option controls Perl-side string flagging: when enabled, result
strings from UTF-8 columns are returned with Perl's internal UTF-8 flag
set, so C<length()>, regex, and other character operations work correctly.

=head2 Reading data

With C<< utf8 => 1 >>, text query results, prepared statement results, and
streaming results are automatically UTF-8-flagged per column based on the
column's charset. Binary and non-UTF-8 columns are returned as raw byte
strings. Column names (the C<$fields> arrayref) are UTF-8-flagged when the
connection charset is C<utf8> or C<utf8mb4>, regardless of this option.

Without C<< utf8 => 1 >>, all result values are byte strings (the default).
Use C<Encode::decode_utf8()> to decode them manually.

=head2 Writing data

No special handling is needed for inserting Unicode. Perl strings (whether
UTF-8-flagged or not) are sent as their underlying byte representation via
C<SvPV>. As long as the connection charset matches the data encoding
(i.e., C<< charset => 'utf8mb4' >> for UTF-8 data), the server receives
and stores the bytes correctly. This applies to both text queries (via
C<query>/C<escape>) and prepared statement parameters (via C<execute>).

=head1 SEE ALSO

L<EV>, L<DBD::MariaDB>, L<AnyEvent::MySQL>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

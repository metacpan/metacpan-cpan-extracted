package EV::Pg;
use strict;
use warnings;
use Carp;

use EV;

BEGIN {
    our $VERSION = '0.02';
    use XSLoader;
    XSLoader::load __PACKAGE__, $VERSION;
}

use Exporter 'import';

our @EXPORT_OK;
our %EXPORT_TAGS;

# Result status constants
use constant {
    PGRES_EMPTY_QUERY    => 0,
    PGRES_COMMAND_OK     => 1,
    PGRES_TUPLES_OK      => 2,
    PGRES_COPY_OUT       => 3,
    PGRES_COPY_IN        => 4,
    PGRES_BAD_RESPONSE   => 5,
    PGRES_NONFATAL_ERROR => 6,
    PGRES_FATAL_ERROR    => 7,
    PGRES_COPY_BOTH      => 8,
    PGRES_SINGLE_TUPLE   => 9,
    PGRES_PIPELINE_SYNC  => 10,
    PGRES_PIPELINE_ABORTED => 11,
    PGRES_TUPLES_CHUNK     => 12,
};

# Connection status
use constant {
    CONNECTION_OK  => 0,
    CONNECTION_BAD => 1,
};

# Transaction status
use constant {
    PQTRANS_IDLE    => 0,
    PQTRANS_ACTIVE  => 1,
    PQTRANS_INTRANS => 2,
    PQTRANS_INERROR => 3,
    PQTRANS_UNKNOWN => 4,
};

# Pipeline status
use constant {
    PQ_PIPELINE_OFF     => 0,
    PQ_PIPELINE_ON      => 1,
    PQ_PIPELINE_ABORTED => 2,
};

use constant {
    PQERRORS_TERSE    => 0,
    PQERRORS_DEFAULT  => 1,
    PQERRORS_VERBOSE  => 2,
    PQERRORS_SQLSTATE => 3,
};

use constant {
    PQSHOW_CONTEXT_NEVER  => 0,
    PQSHOW_CONTEXT_ERRORS => 1,
    PQSHOW_CONTEXT_ALWAYS => 2,
};

use constant {
    PQTRACE_SUPPRESS_TIMESTAMPS => (1<<0),
    PQTRACE_REGRESS_MODE        => (1<<1),
};

$EXPORT_TAGS{status} = [qw(
    PGRES_EMPTY_QUERY PGRES_COMMAND_OK PGRES_TUPLES_OK
    PGRES_COPY_OUT PGRES_COPY_IN PGRES_BAD_RESPONSE
    PGRES_NONFATAL_ERROR PGRES_FATAL_ERROR PGRES_COPY_BOTH
    PGRES_SINGLE_TUPLE PGRES_PIPELINE_SYNC PGRES_PIPELINE_ABORTED
    PGRES_TUPLES_CHUNK
)];

$EXPORT_TAGS{conn} = [qw(CONNECTION_OK CONNECTION_BAD)];

$EXPORT_TAGS{transaction} = [qw(
    PQTRANS_IDLE PQTRANS_ACTIVE PQTRANS_INTRANS
    PQTRANS_INERROR PQTRANS_UNKNOWN
)];

$EXPORT_TAGS{pipeline} = [qw(
    PQ_PIPELINE_OFF PQ_PIPELINE_ON PQ_PIPELINE_ABORTED
)];

$EXPORT_TAGS{verbosity} = [qw(
    PQERRORS_TERSE PQERRORS_DEFAULT PQERRORS_VERBOSE PQERRORS_SQLSTATE
)];

$EXPORT_TAGS{context} = [qw(
    PQSHOW_CONTEXT_NEVER PQSHOW_CONTEXT_ERRORS PQSHOW_CONTEXT_ALWAYS
)];

$EXPORT_TAGS{trace} = [qw(
    PQTRACE_SUPPRESS_TIMESTAMPS PQTRACE_REGRESS_MODE
)];

{
    my %seen;
    @EXPORT_OK = grep { !$seen{$_}++ } map { @$_ } values %EXPORT_TAGS;
    $EXPORT_TAGS{all} = \@EXPORT_OK;
}

*q          = \&query;
*qp         = \&query_params;
*qx         = \&query_prepared;
*prep       = \&prepare;
*reconnect  = \&reset;
*disconnect = \&finish;
*flush      = \&send_flush_request if defined &send_flush_request;
*sync       = \&pipeline_sync;
*quote      = \&escape_literal;
*quote_id   = \&escape_identifier;
*errstr     = \&error_message;
*txn_status = \&transaction_status;
*pid        = \&backend_pid;

sub new {
    my ($class, %args) = @_;

    my $loop = delete $args{loop} || EV::default_loop;
    my $self = $class->_new($loop);

    $self->on_error(delete $args{on_error} // sub { die @_ });
    $self->on_connect(delete $args{on_connect})   if exists $args{on_connect};
    $self->on_notify(delete $args{on_notify})     if exists $args{on_notify};
    $self->on_notice(delete $args{on_notice})     if exists $args{on_notice};
    $self->on_drain(delete $args{on_drain})       if exists $args{on_drain};

    my $keep_alive      = delete $args{keep_alive};
    my $conninfo        = delete $args{conninfo};
    my $conninfo_params = delete $args{conninfo_params};
    my $expand_dbname   = delete $args{expand_dbname};

    if (my @unknown = sort keys %args) {
        Carp::carp("EV::Pg->new: unknown argument(s): @unknown");
    }

    $self->keep_alive(1) if $keep_alive;

    if (defined $conninfo_params) {
        $self->connect_params($conninfo_params, $expand_dbname ? 1 : 0);
    } elsif (defined $conninfo) {
        $self->connect($conninfo);
    }

    $self;
}

1;

__END__

=head1 NAME

EV::Pg - asynchronous PostgreSQL client using libpq and EV

=head1 SYNOPSIS

    use v5.10;
    use EV;
    use EV::Pg;

    my $pg = EV::Pg->new(
        conninfo   => 'dbname=mydb',
        on_error   => sub { die "PG error: $_[0]\n" },
    );
    $pg->on_connect(sub {
        $pg->query_params(
            'select $1::int + $2::int', [10, 20],
            sub {
                my ($rows, $err) = @_;
                die $err if $err;
                say $rows->[0][0];  # 30
                EV::break;
            },
        );
    });
    EV::run;

=head1 DESCRIPTION

EV::Pg is a non-blocking PostgreSQL client that integrates with the L<EV>
event loop.  It drives the libpq async API (C<PQsendQuery>,
C<PQconsumeInput>, C<PQgetResult>) via C<ev_io> watchers on the libpq
socket, so the event loop never blocks on database I/O.

Features: parameterized queries, prepared statements, pipeline mode,
single-row mode, chunked rows (libpq E<gt>= 17), COPY IN/OUT,
LISTEN/NOTIFY, async cancel (libpq E<gt>= 17), structured error fields,
protocol tracing, and notice handling.

=head1 CALLBACKS

Query callbacks receive C<($result)> on success, C<(undef, $error)> on error:

=over

=item B<SELECT> / B<single-row mode>

C<(\@rows)> where each row is an arrayref of column values.
C<undef> columns map to Perl C<undef>.

=item B<INSERT / UPDATE / DELETE>

C<($cmd_tuples)> -- the string returned by C<PQcmdTuples>
(e.g. C<"1">, C<"0">).

=item B<Describe>

C<(\%meta)> with keys C<nfields>, C<nparams>,
and (when non-zero) C<fields> (arrayref of C<< {name, type} >> hashes)
and C<paramtypes> (arrayref of OIDs).

=item B<COPY>

C<("COPY_IN")>, C<("COPY_OUT")>, or C<("COPY_BOTH")>.

=item B<Pipeline sync>

C<(1)>.

=item B<Error>

C<(undef, $error_message)>.

=back

Exceptions thrown inside callbacks are caught and emitted as warnings.

=head1 CONSTRUCTOR

=head2 new

    my $pg = EV::Pg->new(%args);

Arguments:

=over

=item conninfo

libpq connection string.  If provided, C<connect> is called immediately.

=item conninfo_params

Hashref of connection parameters (e.g. C<< { host => 'localhost',
dbname => 'mydb', port => '5432' } >>).  Alternative to C<conninfo>.
If provided, C<connect_params> is called immediately.

=item expand_dbname

If true and C<conninfo_params> is used, the C<dbname> value is parsed
as a connection string (allowing C<< dbname => 'postgresql://...' >>).

=item on_connect

Callback invoked (with no arguments) when the connection is established.

=item on_error

Callback invoked as C<< ($error_message) >> on connection-level errors.
Defaults to C<sub { die @_ }>.

=item on_notify

Callback invoked as C<< ($channel, $payload, $backend_pid) >> on
LISTEN/NOTIFY messages.

=item on_notice

Callback invoked as C<< ($message) >> on PostgreSQL notice/warning
messages.

=item on_drain

Callback invoked (with no arguments) when the send buffer has been
flushed during COPY IN.  Useful for resuming C<put_copy_data> after
it returns 0.

=item keep_alive

When true, the connection keeps C<EV::run> alive even when no queries
are pending.  See L</keep_alive>.

=item loop

An L<EV> loop object.  Defaults to C<EV::default_loop>.

=back

=head1 CONNECTION METHODS

=head2 connect

    $pg->connect($conninfo);

Initiates an asynchronous connection.  The C<on_connect> handler fires
on success; C<on_error> fires on failure.

=head2 connect_params

    $pg->connect_params(\%params);
    $pg->connect_params(\%params, $expand_dbname);

Initiates an asynchronous connection using keyword/value parameters
instead of a connection string.  C<$expand_dbname> allows the C<dbname>
parameter to contain a full connection URI.

=head2 reset

    $pg->reset;

Drops the current connection and reconnects using the original conninfo.
Pending callbacks receive C<(undef, "connection reset")>.
Alias: C<reconnect>.

=head2 finish

    $pg->finish;

Closes the connection.  Pending callbacks receive
C<(undef, "connection finished")>.  Alias: C<disconnect>.

=head2 is_connected

    my $bool = $pg->is_connected;

Returns 1 if connected and ready for queries.

=head2 status

    my $st = $pg->status;

Returns the libpq connection status (C<CONNECTION_OK> or
C<CONNECTION_BAD>).

=head1 QUERY METHODS

=head2 query

    $pg->query($sql, sub { my ($result, $err) = @_; });

Sends a simple query.  B<Not allowed in pipeline mode> -- use
C<query_params> instead.  Multi-statement strings (e.g. C<"SELECT 1;
SELECT 2">) are supported but only the last result is delivered to the
callback.  PostgreSQL stops executing after the first error, so
errors always appear as the last result.

=head2 query_params

    $pg->query_params($sql, \@params, sub { my ($result, $err) = @_; });

Sends a parameterized query.  Parameters are referenced in SQL as
C<$1>, C<$2>, etc.  C<undef> values are sent as SQL NULL.

=head2 prepare

    $pg->prepare($name, $sql, sub { my ($result, $err) = @_; });

Creates a prepared statement.  The callback receives an empty string
(C<"">) on success.  Alias: C<prep>.

=head2 query_prepared

    $pg->query_prepared($name, \@params, sub { my ($result, $err) = @_; });

Executes a prepared statement.  Alias: C<qx>.

=head2 describe_prepared

    $pg->describe_prepared($name, sub { my ($meta, $err) = @_; });

Describes a prepared statement.  The callback receives a hashref with
keys C<nfields> and C<nparams>.  When C<nfields> is non-zero, a C<fields>
key is also present (arrayref of C<< {name, type} >> hashes).  When
C<nparams> is non-zero, a C<paramtypes> key is also present (arrayref
of OIDs).

=head2 describe_portal

    $pg->describe_portal($name, sub { my ($meta, $err) = @_; });

Describes a portal.  The callback receives the same hashref structure
as C<describe_prepared>.

=head2 set_single_row_mode

    my $ok = $pg->set_single_row_mode;

Switches the most recently sent query to single-row mode.  Returns 1
on success, 0 on failure (e.g. no query pending).  The callback fires
once per row with C<(\@rows)> where C<@rows> is an arrayref
containing a single row (e.g. C<[[$col1, $col2, ...]]>), then a
final empty C<(\@rows)> (where C<@rows> has zero elements) for the
completion.

=head2 set_chunked_rows_mode

    my $ok = $pg->set_chunked_rows_mode($chunk_size);

Switches the most recently sent query to chunked rows mode, delivering
up to C<$chunk_size> rows at a time (requires libpq E<gt>= 17).
Like single-row mode, but with lower per-callback overhead for large
result sets.  Returns 1 on success, 0 on failure.

=head2 close_prepared

    $pg->close_prepared($name, sub { my ($result, $err) = @_; });

Closes (deallocates) a prepared statement at protocol level (requires
libpq E<gt>= 17).  The callback receives an empty string (C<"">) on
success.  Works in pipeline mode, unlike C<DEALLOCATE> SQL.

=head2 close_portal

    $pg->close_portal($name, sub { my ($result, $err) = @_; });

Closes a portal at protocol level (requires libpq E<gt>= 17).
The callback receives an empty string (C<"">) on success.

=head2 cancel

    my $err = $pg->cancel;

Sends a cancel request using the legacy C<PQcancel> API.  This is a
B<blocking> call.  Returns C<undef> on success, an error string on
failure.

=head2 cancel_async

    $pg->cancel_async(sub { my ($err) = @_; });

Sends an asynchronous cancel request using the C<PQcancelConn> API
(requires libpq E<gt>= 17).  The callback receives no arguments on
success, or an error string on failure.  Croaks if libpq was built
without async cancel support (C<LIBPQ_HAS_ASYNC_CANCEL>).

=head2 pending_count

    my $n = $pg->pending_count;

Returns the number of callbacks in the queue.

=head2 keep_alive

    $pg->keep_alive(1);
    my $bool = $pg->keep_alive;

When true, the connection's read watcher keeps C<EV::run> alive even when
no queries are pending.  Useful when waiting for server-side C<NOTIFY>
events via C<on_notify> — without this flag the event loop would exit
after the C<LISTEN> query completes.

=head2 skip_pending

    $pg->skip_pending;

Cancels all pending callbacks, invoking each with
C<(undef, "skipped")>.

=head1 PIPELINE METHODS

=head2 enter_pipeline

    $pg->enter_pipeline;

Enters pipeline mode.  Queries are batched and sent without waiting
for individual results.

=head2 exit_pipeline

    $pg->exit_pipeline;

Exits pipeline mode.  Croaks if the pipeline is not idle (has
pending queries).

=head2 pipeline_sync

    $pg->pipeline_sync(sub { my ($ok) = @_; });

Sends a pipeline sync point.  The callback fires with C<(1)> when
all preceding queries have completed.  Alias: C<sync>.

=head2 send_pipeline_sync

    $pg->send_pipeline_sync(sub { my ($ok) = @_; });

Like C<pipeline_sync> but does B<not> flush the send buffer (requires
libpq E<gt>= 17).  Useful for batching multiple sync points before a
single manual flush via C<send_flush_request>.

=head2 send_flush_request

    $pg->send_flush_request;

Sends a flush request, asking the server to deliver results for
queries sent so far.  Alias: C<flush>.

=head2 pipeline_status

    my $st = $pg->pipeline_status;

Returns C<PQ_PIPELINE_OFF>, C<PQ_PIPELINE_ON>, or
C<PQ_PIPELINE_ABORTED>.

=head1 COPY METHODS

=head2 put_copy_data

    my $ok = $pg->put_copy_data($data);

Sends data to the server during a COPY IN operation.  Returns 1 on
success (data flushed or flush scheduled), 0 if the send buffer is
full (wait for writability and retry), or -1 on error.

=head2 put_copy_end

    my $ok = $pg->put_copy_end;
    my $ok = $pg->put_copy_end($errmsg);

Ends a COPY IN operation.  Pass an error message to abort the COPY.
Returns 1 on success, 0 if the send buffer is full (retry after
writability), or -1 on error.

=head2 get_copy_data

    my $row = $pg->get_copy_data;

Retrieves a row during COPY OUT.  Returns the row data as a string,
C<-1> when the COPY is complete, or C<undef> if no data is available
yet.

=head1 HANDLER METHODS

Each handler method is a getter/setter.  Called with an argument, it
sets the handler and returns the new value (or C<undef> if cleared).
Called without arguments, it returns the current handler.

=head2 on_connect

Called with no arguments on successful connection.

=head2 on_error

Called as C<< ($error_message) >> on connection-level errors.

=head2 on_notify

Called as C<< ($channel, $payload, $backend_pid) >> on LISTEN/NOTIFY.

=head2 on_notice

Called as C<< ($message) >> on server notice/warning messages.

=head2 on_drain

Called with no arguments when the libpq send buffer has been fully
flushed during a COPY IN operation.  Use this to resume sending data
after C<put_copy_data> returns 0 (buffer full).

=head1 CONNECTION INFO

String accessors (C<db>, C<user>, C<host>, C<port>, C<error_message>,
C<parameter_status>, C<ssl_attribute>) return C<undef> when not connected.
Integer accessors return a default value (typically 0 or -1).  Methods that require an
active connection (C<client_encoding>, C<set_client_encoding>,
C<set_error_verbosity>, C<set_error_context_visibility>, C<conninfo>)
croak when not connected.

=head2 error_message

Last error message.  Alias: C<errstr>.

=head2 transaction_status

Returns C<PQTRANS_IDLE>, C<PQTRANS_ACTIVE>, C<PQTRANS_INTRANS>,
C<PQTRANS_INERROR>, or C<PQTRANS_UNKNOWN>.  Alias: C<txn_status>.

=head2 parameter_status

    my $val = $pg->parameter_status($name);

Returns a server parameter (e.g. C<"server_version">,
C<"client_encoding">).

=head2 backend_pid

Backend process ID.  Alias: C<pid>.

=head2 server_version

Server version as an integer (e.g. 180000 for 18.0).

=head2 protocol_version

Protocol version (typically 3).

=head2 db

Database name.

=head2 user

Connected user name.

=head2 host

Server host.

=head2 hostaddr

Server IP address.

=head2 port

Server port.

=head2 socket

The underlying file descriptor.

=head2 ssl_in_use

Returns 1 if the connection uses SSL.

=head2 ssl_attribute

    my $val = $pg->ssl_attribute($name);

Returns an SSL attribute (e.g. C<"protocol">, C<"cipher">).

=head2 ssl_attribute_names

    my $names = $pg->ssl_attribute_names;

Returns an arrayref of available SSL attribute names, or C<undef>
if the connection does not use SSL.

=head2 client_encoding

Returns the current client encoding name.

=head2 set_client_encoding

    $pg->set_client_encoding($encoding);

Sets the client encoding (e.g. C<"UTF8">, C<"SQL_ASCII">).
This is a synchronous (blocking) call that stalls the event loop for
one server round trip.  Best called right after C<on_connect> fires,
before any queries are dispatched.  Croaks if there are pending queries
or on failure.

=head2 set_error_verbosity

    my $old = $pg->set_error_verbosity($level);

Sets error verbosity.  Returns the previous setting.

=head2 set_error_context_visibility

    my $old = $pg->set_error_context_visibility($level);

Sets error context visibility.  C<$level> is one of
C<PQSHOW_CONTEXT_NEVER>, C<PQSHOW_CONTEXT_ERRORS> (default), or
C<PQSHOW_CONTEXT_ALWAYS>.  Returns the previous setting.

=head2 error_fields

    my $fields = $pg->error_fields;

Returns a hashref of structured error fields from the most recent
C<PGRES_FATAL_ERROR> result, or C<undef> if no error has occurred.
The value persists until the next fatal error; it is not cleared by
successful queries.  Keys (present only when non-NULL in the server
response):

    sqlstate    severity    primary     detail
    hint        position    context     schema
    table       column      datatype    constraint
    internal_position       internal_query
    source_file source_line source_function

=head2 result_meta

    my $meta = $pg->result_meta;

Returns a hashref of metadata from the most recent query result,
or C<undef> if no result has been delivered.  The value persists until
the next result that carries metadata; it is not cleared by errors or
commands that produce no columns.  Keys:

    nfields       number of columns
    cmd_status    command status string (e.g. "SELECT 3", "INSERT 0 1")
    inserted_oid  OID of inserted row (only present when valid)
    fields        arrayref of column metadata hashrefs:
                    name, type (OID), ftable (OID), ftablecol,
                    fformat (0=text, 1=binary), fsize, fmod

=head2 conninfo

    my $info = $pg->conninfo;

Returns a hashref of the connection parameters actually used by the
live connection (keyword =E<gt> value pairs).

=head2 connection_used_password

    my $bool = $pg->connection_used_password;

Returns 1 if the connection authenticated with a password.

=head2 connection_used_gssapi

    my $bool = $pg->connection_used_gssapi;

Returns 1 if the connection used GSSAPI authentication.

=head2 connection_needs_password

    my $bool = $pg->connection_needs_password;

Returns 1 if the server requested a password during authentication.

=head2 trace

    $pg->trace($filename);

Enables libpq protocol tracing to the specified file.  Useful for
debugging wire-level issues.

=head2 untrace

    $pg->untrace;

Disables protocol tracing and closes the trace file.

=head2 set_trace_flags

    $pg->set_trace_flags($flags);

Sets trace output flags (requires libpq E<gt>= 14).  C<$flags> is a
bitmask of C<PQTRACE_SUPPRESS_TIMESTAMPS> and C<PQTRACE_REGRESS_MODE>.

=head1 UTILITY METHODS

=head2 escape_literal

    my $quoted = $pg->escape_literal($string);

Returns a string literal escaped for use in SQL.  Alias: C<quote>.

=head2 escape_identifier

    my $quoted = $pg->escape_identifier($string);

Returns an identifier escaped for use in SQL.  Alias: C<quote_id>.

=head2 escape_bytea

    my $escaped = $pg->escape_bytea($binary);

Escapes binary data for use in a bytea column.

=head2 encrypt_password

    my $hash = $pg->encrypt_password($password, $user);
    my $hash = $pg->encrypt_password($password, $user, $algorithm);

Encrypts a password for use with C<ALTER ROLE ... PASSWORD>.
C<$algorithm> is optional; defaults to the server's
C<password_encryption> setting (typically C<"scram-sha-256">).

=head2 unescape_bytea

    my $binary = EV::Pg->unescape_bytea($escaped);

Class method.  Unescapes bytea data.

=head2 lib_version

    my $ver = EV::Pg->lib_version;

Class method.  Returns the libpq version as an integer.

=head2 conninfo_parse

    my $params = EV::Pg->conninfo_parse($conninfo);

Class method.  Parses a connection string and returns a hashref of
the recognized keyword/value pairs.  Croaks if the string is invalid.
Useful for validating connection strings before connecting.

=head1 ALIASES

Short aliases for common methods:

    q           query
    qp          query_params
    qx          query_prepared
    prep        prepare
    reconnect   reset
    disconnect  finish
    flush       send_flush_request
    sync        pipeline_sync
    quote       escape_literal
    quote_id    escape_identifier
    errstr      error_message
    txn_status  transaction_status
    pid         backend_pid

=head1 EXPORT TAGS

    :status       PGRES_* result status constants
    :conn         CONNECTION_OK, CONNECTION_BAD
    :transaction  PQTRANS_* transaction status constants
    :pipeline     PQ_PIPELINE_* pipeline status constants
    :verbosity    PQERRORS_* verbosity constants
    :context      PQSHOW_CONTEXT_* context visibility constants
    :trace        PQTRACE_* trace flag constants
    :all          all of the above

=head1 BENCHMARK

500k queries over Unix socket, PostgreSQL 18, libpq 18:

    Workload   EV::Pg sequential  EV::Pg pipeline  DBD::Pg sync  DBD::Pg async+EV
    SELECT          73,109 q/s      124,092 q/s     56,496 q/s      48,744 q/s
    INSERT          58,534 q/s       84,467 q/s     39,068 q/s      41,559 q/s
    UPSERT          26,342 q/s       34,223 q/s     28,134 q/s      27,155 q/s

Sequential mode uses prepared statements (parse once, bind+execute per call).
Pipeline mode batches queries with C<pipeline_sync> every 1000 queries.
See F<bench/bench.pl> to reproduce.

=head1 REQUIREMENTS

libpq E<gt>= 14 (PostgreSQL client library) and L<EV>.
Some features (chunked rows, close prepared/portal, no-flush pipeline
sync, async cancel) require libpq E<gt>= 17.

=head1 SEE ALSO

L<EV>, L<DBD::Pg>, L<Mojo::Pg>, L<AnyEvent::Pg>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

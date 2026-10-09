package EV::Pg;
use strict;
use warnings;
use Carp;

use EV;

BEGIN {
    our $VERSION = '0.09';
    use XSLoader;
    XSLoader::load __PACKAGE__, $VERSION;
}

# Under ithreads, spawned threads get an unblessed copy: no DESTROY runs
# there, so the parent's connection survives thread exit.
sub CLONE_SKIP { 1 }

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
        on_error   => sub { warn "PG error: $_[0]\n"; EV::break },
    );
    $pg->on_connect(sub {
        $pg->query_params(
            'select $1::int + $2::int', [10, 20],
            sub {
                my ($rows, $err) = @_;
                if ($err) { warn $err; EV::break; return; }
                say $rows->[0][0];  # 30
                EV::break;
            },
        );
    });
    EV::run;

=head1 DESCRIPTION

EV::Pg is a non-blocking PostgreSQL client built on top of libpq and
the L<EV> event loop.  It drives the libpq async API (C<PQsendQuery>,
C<PQconsumeInput>, C<PQgetResult>) through C<ev_io> watchers on the
libpq socket, so the event loop never blocks on database I/O.

Features: parameterized queries, prepared statements, pipeline mode,
single-row mode, chunked rows (libpq E<gt>= 17), COPY IN/OUT,
LISTEN/NOTIFY, async cancel (libpq E<gt>= 17), structured error
fields, protocol tracing, and notice handling.

=head1 CALLBACKS

Query callbacks always receive a single positional argument on success
and C<(undef, $error_message)> on error, so

    my ($result, $err) = @_;

works for every shape: C<$result> is the success payload, C<$err> is
defined only on error.  The shape of C<$result> depends on the query:

=over

=item SELECT (or single-row / chunked mode)

C<\@rows> -- arrayref of rows; each row is an arrayref of column values
with SQL NULL mapping to Perl C<undef>.

=item INSERT / UPDATE / DELETE

C<$cmd_tuples> -- the string from C<PQcmdTuples> (e.g. C<"1">, C<"0">).

=item PREPARE / close_prepared / close_portal

C<""> -- always an empty string (these commands return no row count).

=item describe_prepared / describe_portal

C<\%meta> -- hashref with C<nfields>, C<nparams>, and (when non-zero)
C<fields> (arrayref of C<< {name, type} >> hashes) and C<paramtypes>
(arrayref of OIDs).

=item COPY

C<"COPY_IN">, C<"COPY_OUT">, or C<"COPY_BOTH"> -- a string tag
identifying the COPY direction.

=item pipeline_sync

C<1>.

=back

Exceptions thrown inside callbacks are caught and reported via C<warn>
so that one bad callback does not derail the rest of the queue.

All string values are byte strings as returned by libpq, never
decoded characters; decode them yourself (see C<client_encoding>).

A callback may nest C<EV::run>, but while a query callback or
C<on_notice> runs, the object's I/O waits for it to return: never
wait there for pg results, the wait would never end.  Nested waits
from C<on_connect>, C<on_notify> and C<on_drain> work.

=head1 CONSTRUCTOR

=head2 new

    my $pg = EV::Pg->new(%args);

Returns a new EV::Pg object.  If C<conninfo> or C<conninfo_params> is
supplied, an asynchronous connect starts immediately; otherwise call
C<connect> later.

Recognized arguments:

=over

=item conninfo

libpq connection string passed to C<connect>.

=item conninfo_params

Hashref of connection parameters (e.g.
C<< { host => 'localhost', dbname => 'mydb', port => 5432 } >>),
passed to C<connect_params>.  Takes precedence over C<conninfo>
when both are given.

=item expand_dbname

When true together with C<conninfo_params>, the C<dbname> value is
itself parsed as a connection string -- so
C<< dbname => 'postgresql://host/db?sslmode=require' >> works.
Ignored unless C<conninfo_params> is also given.

=item on_connect

Fires with no arguments on every successful handshake,
including each C<reset>.

=item on_error

Fires as C<($error_message)> on connection-level errors.  The default
handler C<die>s, which, like any handler exception, is caught and
reported via C<warn>.  C<< on_error => undef >> still installs the
default; clear it with C<< $pg->on_error(undef) >>.

=item on_notify

Fires as C<($channel, $payload, $backend_pid)> for LISTEN/NOTIFY
messages.

=item on_notice

Fires as C<($message)> for server NOTICE/WARNING messages.

=item on_drain

Fires with no arguments when the libpq send buffer has been fully
flushed during a COPY -- use it to resume sending after
C<put_copy_data> returned 0.

=item keep_alive

When true, the connection keeps C<EV::run> alive even with an empty
callback queue.  See L</keep_alive>.

=item loop

An L<EV> loop object.  Defaults to C<EV::default_loop>.

=back

Unknown arguments produce a C<carp> warning and are otherwise ignored.

=head1 OBJECT LIFECYCLE

Destroying the object (C<undef $pg>, including from inside a
callback) fires every queued callback with
C<(undef, "object destroyed")> and closes the connection.

Handlers that close over C<$pg> form a reference cycle: only
C<undef $pg> (or clearing the handlers) frees the object; scope exit
and C<finish> do not.

After C<fork>, the child inherits a copy it must not use for I/O.
Destroying it (C<undef $pg> or plain C<exit>), C<finish> and
C<skip_pending> are safe: the parent's connection is untouched and
inherited callbacks are dropped silently.  Everything that talks to
the server croaks on the inherited object.  Destroy inherited objects
before running an event loop in the child, and create a new object
there to talk to PostgreSQL.

=head1 CONNECTION METHODS

=head2 connect

    $pg->connect($conninfo);

Starts an asynchronous connection from a libpq connection string.
C<on_connect> fires on success, C<on_error> on failure.  Croaks if
already connected, and synchronously for failures detectable before
the first packet (bad keyword, unresolvable host, missing Unix
socket, on some systems a refused local port); the rest arrive
via C<on_error>.  Do not call C<connect> directly from C<on_error>:
the failed connection is still installed while the handler runs, so
it croaks -- C<finish> first, or defer with a timer like C<reset>.

=head2 connect_params

    $pg->connect_params(\%params);
    $pg->connect_params(\%params, $expand_dbname);

Like C<connect> but takes a hashref of keyword/value parameters.  When
C<$expand_dbname> is true, the C<dbname> entry may itself be a
connection string or URI.  Undef values mean the libpq default.
Croaks if already connected, or synchronously if the parameters
are unusable.

=head2 reset

    $pg->reset;

Drops the current connection and reconnects with the same parameters.
Pending callbacks fire with C<(undef, "connection reset")> first.
Croaks if no connection was ever started.  Alias: C<reconnect>.

Do not call C<reset> directly from C<on_error> against a
possibly-down server: each attempt fails immediately and
reconnects spin hot.  Defer with a timer, and catch the synchronous
failures C<connect> lists:

    on_error => sub {
        my $t; $t = EV::timer(5, 0, sub {
            undef $t;
            eval { $pg->reset; 1 } or $pg->on_error->($@);
        });
    },

=head2 finish

    $pg->finish;

Closes the connection.  Pending callbacks fire with
C<(undef, "connection finished")>.  Alias: C<disconnect>.

=head2 is_connected

    my $bool = $pg->is_connected;

True if the handshake has completed and the connection is ready for
queries.  False during connect, after C<finish>, and after a
connection-level failure.  A failed query (C<PGRES_FATAL_ERROR>)
leaves the connection usable, so it does not affect this flag.

=head2 status

    my $st = $pg->status;

libpq connection status: C<CONNECTION_OK> or C<CONNECTION_BAD>;
intermediate libpq states may show during the handshake.
Returns C<CONNECTION_BAD> when not connected.

=head1 QUERY METHODS

The methods below that issue commands croak when called while not
connected; those taking a callback also croak when it is not a
coderef.  Outside pipeline mode only one query may be in flight;
sending another before the first completes croaks.

=head2 query

    $pg->query($sql, sub { my ($result, $err) = @_; });

Sends a simple query.  Multi-statement strings (e.g.
C<"SELECT 1; SELECT 2">) are accepted, but only the final result
reaches the callback -- intermediate results are silently discarded,
and because PostgreSQL stops at the first error, errors always
arrive as that final result.  B<Not allowed in pipeline mode> -- use
C<query_params> there.  Alias: C<q>.  An empty, whitespace-only or
semicolon-only string yields C<(undef, "empty query")>.

=head2 query_params

    $pg->query_params($sql, \@params, sub { my ($result, $err) = @_; });

Sends a parameterized query.  Parameters are referenced in SQL as
C<$1>, C<$2>, etc.; C<undef> elements become SQL NULL.

Values are sent in PostgreSQL's text format.  Embedded NUL bytes
cause the call to croak (text-format params cannot legally contain
NULs) -- pass binary data through C<escape_bytea> if you need a
C<bytea> column.  The params argument must be an arrayref.  Alias:
C<qp>.

=head2 prepare

    $pg->prepare($name, $sql, sub { my ($result, $err) = @_; });

Creates a prepared statement at the protocol level (no SQL C<PREPARE>
parsing).  The callback receives C<""> on success.  Alias: C<prep>.

=head2 query_prepared

    $pg->query_prepared($name, \@params, sub { my ($result, $err) = @_; });

Executes a prepared statement created by C<prepare>.  Same param
rules as C<query_params>.  Alias: C<qx>.

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

Switches the most recently sent query into single-row mode.  Must be
called immediately after a send method (C<query>, C<query_params>,
...) and before the event loop delivers any results -- a 0 return
means no query was in the right async state and should be treated as
a programmer error rather than a runtime condition.

The query callback then fires once per row with a single-row C<\@rows>
(e.g. C<[[$col0, $col1, ...]]>), and once more at the end with an
empty C<\@rows> as the completion sentinel.

=head2 set_chunked_rows_mode

    my $ok = $pg->set_chunked_rows_mode($chunk_size);

Like C<set_single_row_mode> but delivers up to C<$chunk_size> rows per
callback (requires libpq E<gt>= 17), reducing per-callback overhead for
large result sets.  Same call-timing constraint and same trailing
empty-rows completion sentinel.

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

Sends a cancel request using the legacy C<PQcancel> API.  B<Blocks>
the event loop for one network round trip; prefer C<cancel_async> on
libpq E<gt>= 17.  Returns C<undef> on success or an error string on
failure.

=head2 cancel_async

    $pg->cancel_async(sub { my ($r, $err) = @_; });

Sends a non-blocking cancel request using the C<PQcancelConn> API
(requires libpq E<gt>= 17).  The callback receives C<(1)> on success
or C<(undef, $errmsg)> on failure.  Croaks if a cancel is already in
progress.  Success means the cancel was sent, not that the query
died: a late cancel loses and the query callback still delivers
its result.  There is no timeout; guard with your own timer if
the server may be unreachable.

=head2 pending_count

    my $n = $pg->pending_count;

Number of callbacks currently in the queue (queries sent but not yet
delivered).

=head2 keep_alive

    $pg->keep_alive(1);
    my $bool = $pg->keep_alive;

When true, the read watcher keeps C<EV::run> alive even when the
callback queue is empty.  Required when waiting for server-side
C<NOTIFY> events via C<on_notify> -- without this flag the loop would
exit as soon as the C<LISTEN> query completes.  Getter/setter.

=head2 skip_pending

    $pg->skip_pending;

Drops every queued callback, invoking each with
C<(undef, "skipped")>.  Results still in flight are discarded as they
arrive; until then a send outside pipeline mode croaks with
C<another command is already in progress>, so retry it later.  A
skipped COPY OUT or COPY BOTH is ended and drained automatically; a
skipped COPY IN is aborted when skipped from its own callback,
otherwise end it with C<put_copy_end> (or C<reset>).

=head1 PIPELINE METHODS

Pipeline mode lets you send multiple queries without waiting for
individual results, then receive the results in order after a sync
point.  Inside a pipeline you must use C<query_params> or
C<query_prepared> -- C<query> is rejected.

=head2 enter_pipeline

    $pg->enter_pipeline;

Switches the connection into pipeline mode.  Croaks if there are
unfinished results outstanding.  Do not issue C<COPY ... FROM STDIN>
in pipeline mode: an unfed COPY stalls, and further queries make the
server abort the connection (C<COPY ... TO STDOUT> is fine).  If a
query in a batch fails,
the server skips the rest of the batch and their callbacks fire with
C<(undef, "pipeline aborted")>.

=head2 exit_pipeline

    $pg->exit_pipeline;

Returns to normal mode.  Croaks if the pipeline is not idle.
Succeeds quietly when not in pipeline mode.

=head2 pipeline_sync

    $pg->pipeline_sync(sub { my ($r, $err) = @_; });

Sends a pipeline sync point.  The callback fires with C<(1)> after all
preceding queries in the batch have completed, or
C<(undef, $errmsg)> if the connection drops first.  Croaks outside
pipeline mode.  Alias: C<sync>.

=head2 send_pipeline_sync

    $pg->send_pipeline_sync(sub { my ($r, $err) = @_; });

Like C<pipeline_sync> but does B<not> flush the send buffer (requires
libpq E<gt>= 17).  Useful for batching multiple sync points before a
single manual flush via C<send_flush_request>.  Croaks outside
pipeline mode.

=head2 send_flush_request

    $pg->send_flush_request;

Asks the server to deliver results for queries sent so far -- the
manual companion to C<send_pipeline_sync>.  Alias: C<flush>.

=head2 pipeline_status

    my $st = $pg->pipeline_status;

One of C<PQ_PIPELINE_OFF>, C<PQ_PIPELINE_ON>, or
C<PQ_PIPELINE_ABORTED>.

=head1 COPY METHODS

During a C<COPY> the query callback first fires with a string tag
(C<"COPY_IN"> / C<"COPY_OUT"> / C<"COPY_BOTH">) when streaming starts
-- for COPY OUT and BOTH again whenever more data arrives -- and once
more with the final command result (or error) when the stream ends.
See F<eg/copy_in.pl> and F<eg/copy_out.pl>.

=head2 put_copy_data

    my $rc = $pg->put_copy_data($data);

Sends a chunk during COPY IN.  Returns 1 on success (data buffered or
flushed), or -1 on error; -1 also outside COPY IN state.  libpq grows
its send buffer without limit, so pace large loads yourself (e.g. via
C<on_drain>).  A 0 means the buffer could not grow: wait for
C<on_drain>, then retry.

=head2 put_copy_end

    my $rc = $pg->put_copy_end;
    my $rc = $pg->put_copy_end($errmsg);

Ends a COPY IN.  With C<$errmsg> aborts the COPY server-side.  Same
return convention as C<put_copy_data> (including -1 outside
COPY IN state).

=head2 get_copy_data

    my $row = $pg->get_copy_data;

Retrieves the next row during COPY OUT.  Returns the row bytes,
the integer C<-1> when the stream is complete, or C<undef> if nothing
is currently buffered.  After C<undef>, return from the callback: it
fires again with C<"COPY_OUT"> when more data arrives.  Croaks when
called outside COPY OUT state.

=head1 HANDLER METHODS

Each handler is a getter/setter: pass a coderef to install it
(returning the new value), pass C<undef> to clear it, or call without
arguments to read the current handler.  Passing a defined
non-coderef croaks.

=head2 on_connect

Fires with no arguments after every successful handshake,
including each C<reset>.

=head2 on_error

Fires as C<($error_message)> for connection-level errors (handshake
failure, lost socket, libpq protocol errors).  Per-query errors come
through the query callback, not here.

When the socket is lost, C<on_error> fires with the libpq
error message and every callback still outstanding when the loss is
detected then fires with C<(undef, "connection lost")> (including
C<pipeline_sync> callbacks).  A final server error may reach a query
callback before C<on_error> fires.

=head2 on_notify

Fires as C<($channel, $payload, $backend_pid)> for each
LISTEN/NOTIFY message.  Without a handler, notifications are
silently discarded.

=head2 on_notice

Fires as C<($message)> for server NOTICE/WARNING messages.
Without a handler, notices are silently discarded (this
overrides libpq's stderr default).  The handler runs inside libpq,
so the COPY methods, C<set_client_encoding> and C<encrypt_password>
without an algorithm croak while it runs.

=head2 on_drain

Fires with no arguments when the libpq send buffer has been fully
flushed during a COPY -- use it to resume C<put_copy_data> after a
0 return.

=head1 CONNECTION INFO

String accessors (C<db>, C<user>, C<host>, C<hostaddr>, C<port>,
C<error_message>, C<parameter_status>, C<ssl_attribute>) return
C<undef> when not connected.  Integer accessors return a default
value (0, -1, or the enum's unknown member).  Methods that require an active connection
(C<client_encoding>, C<set_client_encoding>, C<set_error_verbosity>,
C<set_error_context_visibility>, C<conninfo>) croak otherwise.

=head2 error_message

    my $msg = $pg->error_message;

Last error message from libpq.  Alias: C<errstr>.

=head2 transaction_status

    my $st = $pg->transaction_status;

One of C<PQTRANS_IDLE>, C<PQTRANS_ACTIVE>, C<PQTRANS_INTRANS>,
C<PQTRANS_INERROR>, C<PQTRANS_UNKNOWN>.  Alias: C<txn_status>.

=head2 parameter_status

    my $val = $pg->parameter_status($name);

Server parameter value (e.g. C<"server_version">, C<"client_encoding">,
C<"server_encoding">).

=head2 backend_pid

    my $pid = $pg->backend_pid;

Backend process ID.  Alias: C<pid>.

=head2 server_version

    my $ver = $pg->server_version;

Server version as a packed integer: C<MMmmpp> (major * 10000 + minor *
100 + patch) for releases before 10, C<MM0000 + patch> from 10
onwards.  PostgreSQL 18.0 returns C<180000>; 17.5 returns C<170005>.

=head2 protocol_version

    my $ver = $pg->protocol_version;

Frontend/backend protocol version (typically 3).

=head2 db

    my $dbname = $pg->db;

Database name.

=head2 user

    my $user = $pg->user;

Connected user name.

=head2 host

    my $host = $pg->host;

Server host as supplied to C<connect> (may be a hostname or socket dir).

=head2 hostaddr

    my $addr = $pg->hostaddr;

Server IP address (empty string over a Unix socket).

=head2 port

    my $port = $pg->port;

Server port.

=head2 socket

    my $fd = $pg->socket;

Underlying socket file descriptor (for advanced uses such as installing
your own watcher).  Returns -1 when not connected.

=head2 ssl_in_use

    my $bool = $pg->ssl_in_use;

True if the connection is encrypted with SSL.

=head2 ssl_attribute

    my $val = $pg->ssl_attribute($name);

SSL attribute (e.g. C<"protocol">, C<"cipher">, C<"key_bits">).

=head2 ssl_attribute_names

    my $names = $pg->ssl_attribute_names;

Arrayref of available SSL attribute names, or C<undef> if the
connection does not use SSL.

=head2 client_encoding

    my $enc = $pg->client_encoding;

Current client encoding name (e.g. C<"UTF8">).

=head2 set_client_encoding

    $pg->set_client_encoding($encoding);

Sets the client encoding (e.g. C<"UTF8">, C<"SQL_ASCII">).  This is a
synchronous (blocking) call that stalls the event loop for one server
round trip, so it is best invoked right after C<on_connect> fires and
before any queries are dispatched.  Croaks if there are pending
queries or on failure.  Notifications read during the call are
delivered to C<on_notify> before it returns.

=head2 set_error_verbosity

    my $old = $pg->set_error_verbosity($level);

Sets error verbosity.  C<$level> is one of C<PQERRORS_TERSE>,
C<PQERRORS_DEFAULT>, C<PQERRORS_VERBOSE>, or C<PQERRORS_SQLSTATE>.
Returns the previous setting.

=head2 set_error_context_visibility

    my $old = $pg->set_error_context_visibility($level);

Sets error context visibility.  C<$level> is one of
C<PQSHOW_CONTEXT_NEVER>, C<PQSHOW_CONTEXT_ERRORS> (default), or
C<PQSHOW_CONTEXT_ALWAYS>.  Returns the previous setting.

=head2 error_fields

    my $fields = $pg->error_fields;

Returns a hashref of structured error fields from the most recent
C<PGRES_FATAL_ERROR> result, or C<undef> if no fatal error has been
seen.  Persists until the next fatal error; successful queries do not
clear it, but C<reset>/C<finish> do.  Each key is present only when the
corresponding field is non-NULL in the server response:

    sqlstate            severity            primary
    detail              hint                position
    context             schema              table
    column              datatype            constraint
    internal_position   internal_query
    source_file         source_line         source_function

=head2 result_meta

    my $meta = $pg->result_meta;

Returns a hashref of metadata for the most recent query result, or
C<undef> if no result has been delivered.  Refreshed by every
successful result (including commands with no columns, and the
C<COMMAND_OK> that terminates a COPY) but B<not> by errors, COPY tags
while streaming, or pipeline sync results.  Reliable only inside the
callback of the result it describes: after an error, COPY tag or sync
it may return C<undef> or the previous result's metadata.  Cleared by
C<reset>/C<finish>.  The most recent result is retained until the next
one arrives; for very large results prefer single-row or chunked mode.

Keys:

    nfields       number of columns
    cmd_status    command status string (e.g. "SELECT 3", "INSERT 0 1")
    inserted_oid  OID of inserted row -- only present for single-row
                    INSERTs that generated an OID (legacy WITH OIDS
                    tables); absent for normal INSERTs and other commands
    fields        arrayref of column metadata hashrefs:
                    name, type (OID), ftable (OID), ftablecol,
                    fformat (0=text, 1=binary), fsize, fmod

=head2 conninfo

    my $info = $pg->conninfo;

Returns a hashref of the connection parameters actually used by the
live connection (keyword =E<gt> value pairs).  Warning: includes
the password in cleartext when the connection string has one; do
not log it wholesale.

=head2 connection_used_password

    my $bool = $pg->connection_used_password;

Returns 1 if the connection authenticated with a password.

=head2 connection_used_gssapi

    my $bool = $pg->connection_used_gssapi;

Returns 1 if the connection used GSSAPI authentication.
Requires libpq E<gt>= 16 (method not defined below that).

=head2 connection_needs_password

    my $bool = $pg->connection_needs_password;

Returns 1 if the server requested a password during authentication.

=head2 trace

    $pg->trace($filename);

Enables libpq protocol tracing, writing the wire-level frontend/backend
exchange to C<$filename> (truncating it).  Croaks if the file cannot be
opened, or when not connected.  Tracing stops if the connection is reset,
finished, or lost; call C<trace> again after reconnecting.

=head2 untrace

    $pg->untrace;

Stops tracing and closes the trace file.  Safe to call when tracing
is not active.

=head2 set_trace_flags

    $pg->set_trace_flags($flags);

Sets the trace output style.  C<$flags>
is a bitmask of C<PQTRACE_SUPPRESS_TIMESTAMPS> and/or
C<PQTRACE_REGRESS_MODE> (handy when diffing traces).  Croaks when
not connected.

=head1 UTILITY METHODS

C<escape_literal>, C<escape_identifier>, C<escape_bytea> and
C<encrypt_password> require a live connection and croak otherwise.

=head2 escape_literal

    my $quoted = $pg->escape_literal($string);

Quotes and escapes a string for safe interpolation into SQL (wraps
the value in single quotes and doubles internal quotes).  Alias:
C<quote>.

=head2 escape_identifier

    my $quoted = $pg->escape_identifier($string);

Quotes and escapes an identifier for safe interpolation into SQL
(wraps in double quotes).  Alias: C<quote_id>.

=head2 escape_bytea

    my $escaped = $pg->escape_bytea($binary);

Escapes binary bytes into the textual C<bytea> form expected by the
server (the C<\x...> hex notation).  Pair with C<unescape_bytea> to
go the other way.

=head2 encrypt_password

    my $hashed = $pg->encrypt_password($password, $user);
    my $hashed = $pg->encrypt_password($password, $user, $algorithm);

Hashes a password client-side (so the cleartext never reaches the
server) ready to be passed to C<ALTER ROLE ... PASSWORD>.
C<$algorithm> is optional; when omitted the server's
C<password_encryption> setting decides (typically C<"scram-sha-256">).
That lookup blocks like C<set_client_encoding> and croaks with
pending or undrained queries; pass an explicit algorithm to avoid
the server round trip.

=head2 unescape_bytea

    my $binary = EV::Pg->unescape_bytea($escaped);

Class method.  Decodes the textual C<bytea> form back to raw bytes.

=head2 lib_version

    my $ver = EV::Pg->lib_version;

Class method.  Returns the libpq version as an integer (same encoding
as C<server_version>; e.g. C<170000> for libpq 17.0).

=head2 conninfo_parse

    my $params = EV::Pg->conninfo_parse($conninfo);

Class method.  Parses a connection string and returns a hashref of
the recognized keyword/value pairs, croaking if the string is
malformed.  Handy for validating connection strings before
connecting.

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
    SELECT          83,998 q/s      144,939 q/s     73,195 q/s      65,966 q/s
    INSERT          67,053 q/s       85,701 q/s     60,127 q/s      58,329 q/s
    UPSERT          37,360 q/s       43,019 q/s     40,278 q/s      40,173 q/s

Sequential mode uses prepared statements (parse once, bind+execute per call).
Pipeline mode batches queries with C<pipeline_sync> every 1000 queries.
Reproduce with F<bench/bench.pl> (C<BENCH_N> queries per workload,
default 10,000; C<BENCH_BATCH> pipeline batch size, default 1000).

=head1 REQUIREMENTS

libpq E<gt>= 14 (PostgreSQL client library) and L<EV>.  A handful of
features -- chunked rows mode, C<close_prepared>/C<close_portal>,
C<send_pipeline_sync>, and C<cancel_async> -- require libpq E<gt>= 17,
C<connection_used_gssapi> needs E<gt>= 16.  Built against older
headers these methods are not defined; run against an older library
they croak.

=head1 THREADS

EV::Pg is not thread-safe and must not be used across Perl
ithreads, even with separate connections per thread: internal
state is unsynchronized and EV watchers are single-threaded.  Use
separate processes for parallelism.  Spawning a thread while an
object is visible is safe -- the child gets an unusable unblessed
copy and the parent's connection is unaffected.

=head1 SEE ALSO

L<EV>, L<DBD::Pg>, L<Mojo::Pg>, L<AnyEvent::Pg>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

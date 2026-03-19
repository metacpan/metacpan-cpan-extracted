package EV::ClickHouse;
use strict;
use warnings;

use EV;

BEGIN {
    our $VERSION = '0.01';
    use XSLoader;
    XSLoader::load __PACKAGE__, $VERSION;
}

*q          = \&query;
*reconnect  = \&reset;
*disconnect = \&finish;

sub _uri_unescape { my $s = $_[0]; $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge; $s }

sub new {
    my ($class, %args) = @_;

    # Connection URI: clickhouse://user:pass@host:port/database
    if (my $uri = delete $args{uri}) {
        if ($uri =~ m{^clickhouse(?:\+(\w+))?://(?:([^:@]*?)(?::([^@]*))?\@)?([^/:]+)(?::(\d+))?(?:/([^?]*))?(?:\?(.*))?$}) {
            my ($proto, $u, $pw, $h, $p, $db, $qs) = ($1, $2, $3, $4, $5, $6, $7);
            $args{protocol} //= $proto if $proto;
            $args{user}     //= _uri_unescape($u)  if defined $u && $u ne '';
            $args{password} //= _uri_unescape($pw) if defined $pw;
            $args{host}     //= $h;
            $args{port}     //= $p     if defined $p;
            $args{database} //= _uri_unescape($db) if defined $db && $db ne '';
            if (defined $qs) {
                for my $pair (split /&/, $qs) {
                    my ($k, $v) = split /=/, $pair, 2;
                    $args{$k} //= _uri_unescape($v) if defined $k && defined $v;
                }
            }
        } else {
            die "EV::ClickHouse: invalid URI '$uri'\n";
        }
    }

    my $loop = delete $args{loop} || EV::default_loop;
    my $self = $class->_new($loop);

    $self->on_error(exists $args{on_error} ? delete $args{on_error} : sub { die @_ });
    $self->on_connect(delete $args{on_connect})      if exists $args{on_connect};
    $self->on_progress(delete $args{on_progress})    if exists $args{on_progress};
    $self->on_disconnect(delete $args{on_disconnect}) if exists $args{on_disconnect};
    $self->on_trace(delete $args{on_trace})          if exists $args{on_trace};

    my $host     = delete $args{host}     // '127.0.0.1';
    my $port     = delete $args{port};
    my $protocol = delete $args{protocol} // 'http';
    my $user     = delete $args{user}     // 'default';
    my $password = delete $args{password} // '';
    my $db_alias = delete $args{db};
    my $database = delete $args{database} // $db_alias // 'default';
    my $tls      = delete $args{tls}      // 0;
    my $tls_ca_file    = delete $args{tls_ca_file};
    my $tls_skip_verify = delete $args{tls_skip_verify} // 0;

    # options
    my $compress        = delete $args{compress}        // 0;
    my $session_id      = delete $args{session_id};
    my $connect_timeout = delete $args{connect_timeout};
    my $query_timeout   = delete $args{query_timeout};
    my $auto_reconnect    = delete $args{auto_reconnect}    // 0;
    my $keepalive         = delete $args{keepalive}          // 0;
    my $reconnect_delay   = delete $args{reconnect_delay}    // 0;
    my $reconnect_max_delay = delete $args{reconnect_max_delay} // 0;

    # decode options (native protocol)
    my $decode_datetime = delete $args{decode_datetime}  // 0;
    my $decode_decimal  = delete $args{decode_decimal}   // 0;
    my $decode_enum     = delete $args{decode_enum}      // 0;
    my $named_rows      = delete $args{named_rows}       // 0;

    die "EV::ClickHouse: unknown protocol '$protocol' (expected 'http' or 'native')\n"
        unless $protocol eq 'http' || $protocol eq 'native';

    $port //= ($protocol eq 'native') ? 9000 : 8123;

    $self->_set_protocol($protocol eq 'native' ? 1 : 0);
    $self->_set_compress($compress)            if $compress;
    $self->_set_session_id($session_id)        if defined $session_id;
    $self->_set_connect_timeout($connect_timeout) if $connect_timeout;
    $self->_set_query_timeout($query_timeout)  if $query_timeout;
    $self->_set_tls($tls)                      if $tls;
    $self->_set_tls_ca_file($tls_ca_file)      if defined $tls_ca_file;
    $self->_set_tls_skip_verify($tls_skip_verify) if $tls_skip_verify;
    $self->_set_auto_reconnect($auto_reconnect) if $auto_reconnect;
    $self->_set_keepalive($keepalive)          if $keepalive;
    $self->_set_reconnect_delay($reconnect_delay) if $reconnect_delay;
    $self->_set_reconnect_max_delay($reconnect_max_delay) if $reconnect_max_delay;

    # compute decode_flags bitmask
    my $decode_flags = 0;
    $decode_flags |= 1 if $decode_datetime;  # DECODE_DT_STR
    $decode_flags |= 2 if $decode_decimal;   # DECODE_DEC_SCALE
    $decode_flags |= 4 if $decode_enum;      # DECODE_ENUM_STR
    $decode_flags |= 8 if $named_rows;       # DECODE_NAMED_ROWS
    $self->_set_decode_flags($decode_flags)   if $decode_flags;

    my $settings = delete $args{settings};
    $self->_set_settings($settings)            if $settings;

    warn "EV::ClickHouse->new: unknown parameter(s): " . join(', ', sort keys %args) . "\n"
        if %args;

    $self->connect($host, $port, $user, $password, $database);

    $self;
}

1;

__END__

=head1 NAME

EV::ClickHouse - Async ClickHouse client using EV

=head1 SYNOPSIS

    use EV;
    use EV::ClickHouse;

    my $ch = EV::ClickHouse->new(
        host       => '127.0.0.1',
        port       => 8123,
        protocol   => 'http',       # or 'native'
        user       => 'default',
        password   => '',
        database   => 'default',
        settings   => { max_threads => 4 },  # connection-level defaults
        on_connect => sub { print "connected\n" },
        on_error   => sub { warn "error: $_[0]\n" },
    );

    # simple query
    $ch->query("select * from system.one", sub {
        my ($rows, $err) = @_;
        if ($err) { warn $err; return }
        for my $row (@$rows) {
            print join(", ", @$row), "\n";
        }
    });

    # query with per-query settings
    $ch->query("select 1", { max_execution_time => 30 }, sub {
        my ($rows, $err) = @_;
    });

    # insert data (TSV string)
    $ch->insert("my_table", "1\tfoo\n2\tbar\n", sub {
        my (undef, $err) = @_;
        warn "insert error: $err" if $err;
    });

    # insert data (arrayref — no escaping needed)
    $ch->insert("my_table", [
        [1, "foo"],
        [2, "bar"],
    ], sub {
        my (undef, $err) = @_;
        warn "insert error: $err" if $err;
    });

    # insert with async_insert
    $ch->insert("my_table", [[1, "foo"]], { async_insert => 1 }, sub {
        my (undef, $err) = @_;
    });

    # raw mode — get response body as-is (HTTP only)
    $ch->query("SELECT * FROM my_table FORMAT CSV", { raw => 1 }, sub {
        my ($body, $err) = @_;
        print $body;  # raw CSV text
    });

    EV::run;

=head1 DESCRIPTION

EV::ClickHouse is an asynchronous ClickHouse client that integrates with
the EV event loop. It supports both the HTTP (port 8123) and native TCP
(port 9000) protocols, implemented directly in XS without external
ClickHouse client libraries.

Key features:

=over 4

=item * HTTP protocol with queued request delivery

=item * Native TCP protocol with binary column-oriented data

=item * Gzip compression (HTTP) and LZ4 compression (native)

=item * TLS/SSL support via OpenSSL (with skip-verify option)

=item * TabSeparated format parsing

=item * INSERT with data support

=item * Session management (HTTP)

=item * Query/connect timeouts and auto-reconnect

=item * Query cancellation

=item * Streaming results via on_data callback

=item * Opt-in decode of Date/DateTime, Decimal, Enum columns

=item * Named rows (hashref) mode

=back

=head1 CONSTRUCTOR

=head2 new

    my $ch = EV::ClickHouse->new(%args);

B<Connection parameters:>

=over 4

=item host => $hostname

Server hostname. Default: C<127.0.0.1>.

B<Note:> DNS resolution is currently blocking. For fully asynchronous behavior,
use an IP address or a local caching resolver.

=item port => $port

Server port. Default: C<8123> for HTTP, C<9000> for native.

=item protocol => 'http' | 'native'

Protocol to use. Default: C<http>.

=item user => $username

Username. Default: C<default>.

=item password => $password

Password. Default: empty.

=item database => $dbname

Default database. Default: C<default>. Also accepts C<db>.

=item tls => 0 | 1

Enable TLS. Default: C<0>.

=item tls_ca_file => $path

Path to a CA certificate file for TLS verification. If provided, it will be
used in addition to system default CA paths.

=item tls_skip_verify => 0 | 1

Skip TLS certificate verification. Default: C<0>.
Useful for self-signed certificates in development.

=back

B<Callbacks:>

=over 4

=item on_connect => sub { }

Called when the connection is established.

=item on_error => sub { my ($message) = @_ }

Called on connection-level errors. Default: C<sub { die @_ }>.

=item on_progress => sub { my ($rows, $bytes, $total_rows, $written_rows, $written_bytes) = @_ }

Called on native protocol progress packets. Not fired for HTTP.

=item on_disconnect => sub { }

Called when the connection is closed (either by C<finish()>, server disconnect,
or error). Useful for reconnect logic or cleanup.

=item on_trace => sub { my ($message) = @_ }

Debug trace callback. Called with internal state machine messages
(e.g. query dispatch). Useful for debugging protocol issues.

=back

B<Options:>

=over 4

=item compress => 0 | 1

Enable compression. Default: C<0>.

=item session_id => $id

HTTP session ID for stateful operations.

=item connect_timeout => $seconds

Connection timeout in seconds.

=item query_timeout => $seconds

Default query timeout applied to all queries. Can be overridden per-query
via the C<query_timeout> key in the settings hashref.

=item auto_reconnect => 0 | 1

Automatically reconnect on connection loss. Default: C<0>.
When enabled, queued (unsent) queries are preserved across reconnects;
in-flight queries receive an error callback.

=item settings => \%hash

Connection-level ClickHouse settings applied to every query and insert.
Per-query settings (see L</query>, L</insert>) override these defaults.

    settings => { async_insert => 1, max_threads => 4 }

=item keepalive => $seconds

Send periodic native protocol ping packets to keep the connection alive
during idle periods. Set to C<0> (default) to disable. Only effective
with the native protocol.

=item reconnect_delay => $seconds

Initial delay for reconnect backoff when C<auto_reconnect> is enabled.
The delay doubles after each failed attempt, up to C<reconnect_max_delay>.
Set to C<0> (default) for immediate reconnect (no backoff).

=item reconnect_max_delay => $seconds

Maximum reconnect delay. Default: C<0> (no cap).

=back

B<Decode options (native protocol only):>

These options control how column values are formatted when returned from
the native protocol. All are opt-in and default to C<0> (returning raw
numeric values for backward compatibility).

=over 4

=item decode_datetime => 0 | 1

Return C<Date>, C<Date32>, C<DateTime>, and C<DateTime64> columns as
formatted strings (e.g. C<"2024-01-15">, C<"2024-01-15 10:30:00">) instead
of raw integer values. Uses UTC by default; if the column has an explicit
timezone (e.g. C<DateTime('America/New_York')>), values are converted to
that timezone.

=item decode_decimal => 0 | 1

Return C<Decimal32>/C<Decimal64>/C<Decimal128> columns as scaled
floating-point numbers instead of unscaled integers.

=item decode_enum => 0 | 1

Return C<Enum8>/C<Enum16> columns as string labels instead of numeric codes.

=item named_rows => 0 | 1

Return each row as a hashref (keyed by column name) instead of an arrayref.

    my $ch = EV::ClickHouse->new(named_rows => 1, ...);
    $ch->query("SELECT 1 as n", sub {
        my ($rows, $err) = @_;
        print $rows->[0]{n};  # 1
    });

=back

=head1 METHODS

=head2 query

    $ch->query($sql, sub { my ($rows, $err) = @_ });
    $ch->query($sql, \%settings, sub { my ($rows, $err) = @_ });

Executes a SQL query. For SELECT: callback receives C<($arrayref_of_arrayrefs)>.
For DDL/DML: callback receives C<(undef)> on success.
On error: C<(undef, $error_message)>.

The optional C<\%settings> hashref passes per-query ClickHouse settings
(e.g. C<max_execution_time>, C<max_threads>). These override any
connection-level defaults. Special keys (not sent to the server):

=over 4

=item C<query_id> — sets the query identifier (protocol-level field)

=item C<raw> — HTTP only. When true, the callback receives the raw response
body as a scalar string instead of parsed rows. Use this with an explicit
C<FORMAT> clause (CSV, JSONEachRow, Parquet, etc.):

    $ch->query("SELECT * FROM t FORMAT CSV", { raw => 1 }, sub {
        my ($body, $err) = @_;
        # $body is the raw CSV text
    });

Not supported with the native protocol (croaks).

=item C<query_timeout> — per-query timeout in seconds, overriding the
connection-level C<query_timeout>.

=item C<on_data> — native protocol only. A code ref called for each data
block as it arrives. Enables streaming: rows are delivered incrementally
and not accumulated.

    $ch->query("SELECT * FROM big_table",
        { on_data => sub { my ($rows) = @_; process_batch($rows) } },
        sub { my (undef, $err) = @_; ... }  # final callback
    );

=back

B<Native protocol type notes:> With the native protocol, column values
are returned as typed Perl scalars by default. C<Date> and C<DateTime>
columns return integer values (days since epoch and Unix timestamps);
enable C<decode_datetime> for formatted strings. C<Enum> columns return
numeric codes; enable C<decode_enum> for string labels. C<Decimal>
columns return unscaled integers; enable C<decode_decimal> for scaled
floats. C<SimpleAggregateFunction> columns are transparently decoded as
their inner type. C<Nested> columns are decoded as arrays of tuples.
C<LowCardinality> columns work across multi-block results with shared
dictionaries.

=head2 insert

    $ch->insert($table, $data, sub { my (undef, $err) = @_ });
    $ch->insert($table, $data, \%settings, sub { my (undef, $err) = @_ });

C<$data> can be either:

=over 4

=item * A string in TabSeparated format (tab-separated columns, newline-separated rows)

=item * An arrayref of arrayrefs: C<[ [$col1, $col2, ...], ... ]>

=back

When using arrayrefs, values are encoded directly without TSV escaping:
C<undef> maps to NULL, strings may contain tabs and newlines freely,
arrayrefs encode Array/Tuple columns, and hashrefs encode Map columns.

    # TSV string (existing)
    $ch->insert("my_table", "1\thello\n2\tworld\n", sub { ... });

    # Arrayref (new) — no escaping needed
    $ch->insert("my_table", [
        [1, "hello\tworld"],      # embedded tab
        [2, undef],               # NULL
        [3, [10, 20]],            # Array column
    ], sub { ... });

The optional C<\%settings> hashref works the same as in L</query>.

=head2 ping

    $ch->ping(sub { my ($result, $err) = @_ });

Checks if the connection is alive. On success C<$result> is a true value
and C<$err> is undef.  On error: C<(undef, $error_message)>.

=head2 finish

    $ch->finish;

Disconnects. Cancels pending operations.

=head2 reset

    $ch->reset;

Disconnects and reconnects using original parameters.

=head2 drain

    $ch->drain(sub { ... });

Registers a callback to be invoked when all pending queries have completed.
If no queries are pending, the callback fires immediately (synchronously).
Useful for graceful shutdown: queue your final queries, then call C<drain>
with a callback that calls C<finish>.

    $ch->query("SELECT 1", sub { ... });
    $ch->query("SELECT 2", sub { ... });
    $ch->drain(sub {
        print "all done\n";
        $ch->finish;
    });

=head2 cancel

    $ch->cancel;

Cancels the currently running query. For the native protocol, sends a
CLIENT_CANCEL packet. For HTTP, closes the connection. Pending callbacks
receive an error.

=head2 skip_pending

    $ch->skip_pending;

Cancels all pending operations. Each pending callback is invoked
with C<(undef, $error_message)>. If a request is currently in flight,
the connection is closed (subsequent queries require reconnection
via C<reset>).

=head1 ACCESSORS

=over 4

=item is_connected

Returns true if the connection is established.

=item pending_count

Number of pending (queued + in-flight) operations.

=item server_info

Full server identification string (e.g. C<"ClickHouse 24.1.0 (revision 54429)">).
Only available with the native protocol (populated from ServerHello).
Returns C<undef> for HTTP connections.

=item server_version

Server version string (e.g. C<"24.1.0">). Only available with the native
protocol. Returns C<undef> for HTTP connections.

=item server_timezone

Server timezone string (e.g. C<"UTC">, C<"Europe/Moscow">). Only available
with the native protocol. Returns C<undef> for HTTP connections.

=item column_names

Returns an arrayref of column names from the last native protocol query
result, or C<undef> if no query has been executed yet.

    $ch->query("SELECT 1 as foo, 2 as bar", sub {
        my $names = $ch->column_names;  # ['foo', 'bar']
    });

=item column_types

Returns an arrayref of ClickHouse type strings from the last native protocol
query result (e.g. C<['UInt32', 'String', 'Nullable(DateTime)']>), or
C<undef> if no query has been executed yet.

=item last_query_id

Returns the query_id of the last dispatched query, or C<undef> if none.
Set via C<< { query_id => 'my-id' } >> in the settings hash of C<query>
or C<insert>.

=item last_error_code

Returns the ClickHouse error code (integer) from the last server error,
or C<0> if no error. Useful for distinguishing retryable errors (e.g.
C<202> = C<TOO_MANY_SIMULTANEOUS_QUERIES>) from permanent ones (e.g.
C<60> = C<UNKNOWN_TABLE>).

=item last_totals

Returns an arrayref of totals rows from the last native protocol query
that used C<WITH TOTALS>, or C<undef> if none.

=item last_extremes

Returns an arrayref of extremes rows from the last native protocol query,
or C<undef> if none.

=item profile_rows_before_limit

Number of rows that would have been returned without C<LIMIT>, from the
last query's profile info. Useful for pagination.

=item profile_rows

Total rows processed by the last query.

=item profile_bytes

Total bytes processed by the last query.

=back

=head1 ALIASES

    q          -> query
    reconnect  -> reset
    disconnect -> finish

=head1 SEE ALSO

L<EV>, L<EV::Pg>, L<EV::MariaDB>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

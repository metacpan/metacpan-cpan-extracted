package EV::ClickHouse;
use strict;
use warnings;

use EV;

BEGIN {
    our $VERSION = '0.02';
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
    # host accepts a bracketed IPv6 literal (e.g. clickhouse://[::1]:9000/db)
    if (my $uri = delete $args{uri}) {
        if ($uri =~ m{^clickhouse(?:\+(\w+))?://(?:([^:@]*?)(?::([^@]*))?\@)?(\[[^\]]+\]|[^/:?]+)(?::(\d+))?(?:/([^?]*))?(?:\?(.*))?$}) {
            my ($proto, $u, $pw, $h, $p, $db, $qs) = ($1, $2, $3, $4, $5, $6, $7);
            $h =~ s/^\[(.*)\]$/$1/;
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

    # Discrete parameters
    my $ch = EV::ClickHouse->new(
        host       => '127.0.0.1',
        port       => 9000,
        protocol   => 'native',     # or 'http'
        user       => 'default',
        password   => '',
        database   => 'default',
        settings   => { max_threads => 4 },  # connection-level defaults
        on_connect => sub { print "connected\n" },
        on_error   => sub { warn "error: $_[0]\n" },
    );

    # Or via URI: clickhouse[+native]://user:pass@host:port/db?key=val
    my $ch = EV::ClickHouse->new(
        uri        => 'clickhouse+native://default:@127.0.0.1:9000/default',
        on_connect => sub { ... },
    );

    # SELECT
    $ch->query("SELECT number FROM system.numbers LIMIT 3", sub {
        my ($rows, $err) = @_;
        die $err if $err;
        print "row: @$_\n" for @$rows;     # row: 0 / row: 1 / row: 2
    });

    # Per-query settings + parameterized values (no string interpolation)
    $ch->query(
        "SELECT {x:UInt32} + {y:UInt32} AS sum",
        { params => { x => 40, y => 2 }, max_execution_time => 30 },
        sub { my ($rows, $err) = @_; print $rows->[0][0], "\n" },  # 42
    );

    # INSERT - arrayref of rows (no TSV escaping needed)
    $ch->insert("my_table", [
        [1, "hello\tworld"],   # embedded tab is fine
        [2, undef],            # NULL
        [3, [10, 20]],         # Array column
    ], sub { my (undef, $err) = @_; warn "insert: $err" if $err });

    # INSERT - pre-formatted TSV string
    $ch->insert("my_table", "1\tfoo\n2\tbar\n", sub { ... });

    # Raw HTTP response body (HTTP only)
    $ch->query("SELECT * FROM t FORMAT CSV", { raw => 1 }, sub {
        my ($body, $err) = @_;
        print $body;
    });

    EV::run;

=head1 DESCRIPTION

EV::ClickHouse is an asynchronous ClickHouse client that integrates with
the L<EV> event loop. It speaks both the ClickHouse HTTP protocol
(port 8123) and the native TCP protocol (port 9000) directly in XS, with
no external ClickHouse client library linked. zlib is required; OpenSSL
(for TLS) and liblz4 (for native compression) are optional and detected
at build time.

=head2 Features

=over 4

=item * HTTP and native TCP protocols, with the same Perl API

=item * gzip compression (HTTP) and LZ4 compression with CityHash
checksums (native)

=item * TLS/SSL via OpenSSL, with optional C<tls_skip_verify> for
self-signed certs and C<tls_ca_file> for additional roots

=item * Connection URIs (C<clickhouse[+native]://user:pass@host:port/db>),
including bracketed IPv6 literals

=item * Per-query and connection-level ClickHouse settings; parameterized
queries via C<params>

=item * Auto-reconnect with exponential backoff; queued (unsent) queries
are preserved across reconnects

=item * Keepalive pings for idle native connections; graceful drain;
query cancellation and skip_pending

=item * Streaming results via C<on_data> per-block callback (native);
on_progress for native progress packets

=item * Raw HTTP response mode for CSV / JSONEachRow / Parquet / etc.

=item * 30+ ClickHouse types including Decimal128, UUID, IPv4/IPv6,
Nullable, Array, Tuple, Map, LowCardinality (with cross-block dictionaries),
SimpleAggregateFunction, Nested

=item * Opt-in decode of Date/DateTime, Decimal, and Enum columns; named-rows
(hashref) mode

=back

=head1 CONSTRUCTOR

=head2 new

    my $ch = EV::ClickHouse->new(%args);

The connection is initiated immediately; C<new> returns before it
completes. Queries issued before C<on_connect> fires are queued and
dispatched once the connection is ready.

B<Connection parameters:>

=over 4

=item uri => $uri_string

Single-string connection target:
C<clickhouse[+native]://user:pass@host:port/database?key=value>.

The C<+native> suffix selects the native protocol; otherwise HTTP is used.
Hostnames, IPv4 addresses, and bracketed IPv6 literals are all accepted
(e.g. C<clickhouse://[::1]:9000/db>). Query-string values are merged into
the constructor arguments. Discrete C<host>, C<port>, etc. arguments
override the URI.

=item host => $hostname

Server hostname. Default: C<127.0.0.1>.

B<Note:> DNS resolution is currently blocking. For fully asynchronous
behaviour, use an IP literal or a local caching resolver.

=item port => $port

Server port. Default: C<8123> (HTTP), C<9000> (native).

=item protocol => 'http' | 'native'

Protocol to use. Default: C<http>.

=item user => $username

Username. Default: C<default>.

=item password => $password

Password. Default: empty.

=item database => $dbname

Default database. Default: C<default>. The shorter alias C<db> is also
accepted.

=item tls => 0 | 1

Enable TLS. Default: C<0>. Requires the module to be built with OpenSSL
(otherwise the constructor croaks).

=item tls_ca_file => $path

Additional CA certificate file for TLS verification, used alongside the
system trust store.

=item tls_skip_verify => 0 | 1

Skip TLS certificate verification. Default: C<0>. Useful in development
with self-signed certs; do not use in production.

=item loop => $ev_loop

EV event loop object. Default: C<EV::default_loop>.

=back

B<Callbacks:>

=over 4

=item on_connect => sub { }

Called once the connection is fully established (after the native
ServerHello, or after the TCP/TLS handshake for HTTP).

=item on_error => sub { my ($message) = @_ }

Called on connection-level errors (DNS failure, socket error, TLS failure,
read/write errors, etc.). Default: C<sub { die @_ }>. Per-query errors
are delivered to the query's own callback as the second argument; they
do not invoke C<on_error>.

When a connection drops mid-flight, C<on_error> fires first with the
underlying cause, and C<on_disconnect> fires immediately after as the
state machine tears the socket down. If C<auto_reconnect> is set, the
reconnect attempt happens after C<on_disconnect> returns.

=item on_progress => sub { my ($rows, $bytes, $total_rows, $written_rows, $written_bytes) = @_ }

Called on native protocol progress packets. Not fired for HTTP.

=item on_disconnect => sub { }

Called when the connection is closed (by C<finish>, server disconnect, or
error). Fires after internal state has been reset, so it is safe to queue
new queries or call C<reset> from inside the handler.

=item on_trace => sub { my ($message) = @_ }

Debug trace callback. Called with internal state-machine messages
(connect, dispatch, disconnect). Useful for diagnosing protocol issues.

=back

B<Options:>

=over 4

=item compress => 0 | 1

Enable compression: gzip on HTTP (request and response), LZ4 with CityHash
checksums on the native protocol. Default: C<0>. Native compression
requires liblz4 at build time.

=item session_id => $id

HTTP session id for stateful operations (temporary tables, SET, etc.).
Native protocol has stateful sessions intrinsically; this option is HTTP-only.

=item connect_timeout => $seconds

TCP/TLS connection timeout. C<0> (default) means no timeout. Floating
point allowed.

=item query_timeout => $seconds

Default per-query timeout applied to every query and insert. The query
callback receives a C<timeout> error if exceeded. Override per-call via
the C<query_timeout> key in the settings hashref.

=item auto_reconnect => 0 | 1

Reconnect automatically on connection loss. Default: C<0>. When enabled,
queued (unsent) queries are preserved across reconnects; in-flight queries
receive an error.

=item settings => \%hash

ClickHouse settings applied to every query and insert. Per-call settings
(see L</query>, L</insert>) override these.

    settings => { async_insert => 1, max_threads => 4 }

=item keepalive => $seconds

Send a native protocol PING every N seconds while the connection is idle.
Default: C<0> (disabled). Native protocol only.

=item reconnect_delay => $seconds

Initial delay for the C<auto_reconnect> exponential backoff. Each failed
attempt doubles the delay, capped at C<reconnect_max_delay>. Default:
C<0> (immediate retry, no backoff).

=item reconnect_max_delay => $seconds

Backoff ceiling. Default: C<0>, meaning no explicit cap; the implementation
still bounds the backoff exponent at 20 doublings, so with
C<reconnect_delay = 0.5> the worst case is roughly 6 days. Setting an
explicit ceiling is recommended in production.

=back

B<Decode options (native protocol only):>

These shape how column values are returned. All are opt-in and default
to C<0>, which returns raw numeric forms for stable round-tripping.

=over 4

=item decode_datetime => 0 | 1

Return C<Date>, C<Date32>, C<DateTime>, and C<DateTime64> as formatted
strings (e.g. C<"2024-01-15">, C<"2024-01-15 10:30:00">) instead of raw
integers. Uses UTC; columns with an explicit timezone
(C<DateTime('America/New_York')>) are converted to that zone.

=item decode_decimal => 0 | 1

Return C<Decimal32>/C<Decimal64>/C<Decimal128> as scaled floating-point
numbers instead of unscaled integers. Note: at large precisions, double
loses bits, so leave disabled if you need exact arithmetic.

=item decode_enum => 0 | 1

Return C<Enum8>/C<Enum16> as string labels instead of numeric codes.

=item named_rows => 0 | 1

Return each row as a hashref keyed by column name instead of an arrayref.

    my $ch = EV::ClickHouse->new(named_rows => 1, ...);
    $ch->query("SELECT 1 AS n", sub {
        my ($rows, $err) = @_;
        print $rows->[0]{n};  # 1
    });

=back

=head1 METHODS

=head2 query

    $ch->query($sql, sub { my ($rows, $err) = @_ });
    $ch->query($sql, \%settings, sub { my ($rows, $err) = @_ });

Executes a SQL statement. The callback receives:

=over 4

=item * C<($arrayref_of_arrayrefs)> for SELECT with at least one row

=item * C<(undef)> for DDL/DML on success and for SELECT with zero rows
on the native protocol (HTTP returns an empty arrayref). When in doubt,
treat C<undef> and C<[]> equivalently with C<my @rows = @{$rows // []};>.

=item * C<(undef, $error_message)> on error (server exception or
connection error)

=back

The optional C<\%settings> hashref passes per-query ClickHouse settings
(C<max_execution_time>, C<max_threads>, C<async_insert>, etc.), overriding
connection-level defaults.

The following keys are intercepted by the client and not sent verbatim
to the server:

=over 4

=item C<params => \%hash>

Parameterized values for C<{name:Type}> placeholders in the SQL. Encoding
and quoting is the server's job, so values do not need escaping:

    $ch->query(
        "SELECT * FROM t WHERE id = {id:UInt64} AND name = {n:String}",
        { params => { id => 42, n => "O'Brien" } },
        sub { ... },
    );

Works on both protocols (HTTP uses URL-encoded C<param_*> query string;
native uses dedicated wire fields).

=item C<query_id => $string>

Set the protocol-level query identifier. Retrievable later via
L</last_query_id>.

=item C<raw => 1>

HTTP only. The callback receives the raw response body as a scalar string
instead of parsed rows. Use with an explicit C<FORMAT> clause:

    $ch->query("SELECT * FROM t FORMAT CSV", { raw => 1 }, sub {
        my ($body, $err) = @_;
    });

Croaks if used with the native protocol.

=item C<query_timeout => $seconds>

Per-query timeout, overriding the connection-level C<query_timeout>.

=item C<on_data => sub { my ($rows) = @_; ... }>

Native protocol only. A code ref called for each data block as it arrives,
for streaming large result sets. Rows are delivered incrementally and
B<not> accumulated, so the final callback receives C<(undef)> rather than
all rows. The final callback always fires on completion or error, even if
no data block was emitted (empty result, server-side error before the
first block).

    $ch->query("SELECT * FROM big_table",
        { on_data => sub { my ($rows) = @_; process_batch($rows) } },
        sub { my (undef, $err) = @_; warn $err if $err },
    );

=back

B<Native protocol type notes:> values come back as typed Perl scalars.
By default C<Date>/C<DateTime> are integers (days since epoch / Unix
timestamps); enable C<decode_datetime> for strings. C<Enum> values are
numeric codes; C<decode_enum> returns labels. C<Decimal> values are
unscaled integers; C<decode_decimal> scales them to floats.
C<SimpleAggregateFunction> is transparently decoded as its inner type.
C<Nested> columns become arrays of tuples. C<LowCardinality> works
correctly across multi-block results with shared dictionaries.

=head2 insert

    $ch->insert($table, $data, sub { my (undef, $err) = @_ });
    $ch->insert($table, $data, \%settings, sub { my (undef, $err) = @_ });

C<$data> may be either:

=over 4

=item * A pre-formatted TabSeparated string (tabs separate columns,
newlines separate rows, with the standard ClickHouse escapes).

=item * An arrayref of arrayrefs (rows of column values).

=back

When using arrayrefs, no TSV escaping is needed: C<undef> maps to NULL
and strings may contain tabs and newlines freely.

Nested arrayrefs (Array/Tuple columns) and hashrefs (Map columns) are
supported B<only on the native protocol>, where the encoder has the
column type from the server's sample block. On HTTP the same call
croaks rather than silently produce malformed TSV; use the native
protocol or pre-serialise nested types into ClickHouse TSV literal form.

    # Native: nested types encode directly.
    $ch->insert("my_table", [
        [1, "hello\tworld"],   # embedded tab
        [2, undef],            # NULL
        [3, [10, 20]],         # Array column   (native only)
        [4, { a => 1, b => 2 }],  # Map column  (native only)
    ], sub { ... });

The optional C<\%settings> hashref works exactly as in L</query>,
including C<query_id>, C<query_timeout>, and C<params>.

=head2 ping

    $ch->ping(sub { my ($result, $err) = @_ });

Send a no-op round trip to verify the connection is alive. On success
C<$result> is true, C<$err> is C<undef>. On error: C<(undef, $error)>.

=head2 finish

    $ch->finish;

Close the connection. Pending queries receive an error callback. Aliased
as C<disconnect>.

=head2 reset

    $ch->reset;

Disconnect and immediately reconnect using the original parameters.
Aliased as C<reconnect>.

=head2 drain

    $ch->drain(sub { ... });

Register a callback to fire once all pending queries (queued + in-flight)
have completed. If nothing is pending, the callback fires synchronously.
The classic graceful-shutdown pattern:

    $ch->query("SELECT 1", sub { ... });
    $ch->query("SELECT 2", sub { ... });
    $ch->drain(sub {
        $ch->finish;
        EV::break;
    });

=head2 cancel

    $ch->cancel;

Cancel the currently in-flight query. Native protocol sends CLIENT_CANCEL
and waits for the server's EndOfStream/Exception; HTTP closes the connection
(use C<auto_reconnect> or call L</reset> to recover). The query's callback
receives an error.

=head2 skip_pending

    $ch->skip_pending;

Drop every pending operation: each queued and in-flight callback is invoked
with C<(undef, $error_message)>. If a request was on the wire, the connection
is torn down; call L</reset> (or rely on C<auto_reconnect>) before issuing
new queries.

=head1 ACCESSORS

=over 4

=item is_connected

True if the connection is established.

=item pending_count

Number of pending operations (queued + in-flight).

=item server_info

Full server identification string (e.g. C<"ClickHouse 24.1.0 (revision 54459)">),
populated from the native ServerHello. C<undef> for HTTP connections.

=item server_version

Server version (e.g. C<"24.1.0">). Native only; C<undef> for HTTP.

=item server_timezone

Server timezone (e.g. C<"UTC">, C<"Europe/Moscow">). Native only; C<undef>
for HTTP.

=item column_names

Arrayref of column names from the most recent native query result, or
C<undef> if no query has run.

    $ch->query("SELECT 1 AS foo, 2 AS bar", sub {
        my $names = $ch->column_names;  # ['foo', 'bar']
    });

=item column_types

Arrayref of ClickHouse type strings from the most recent native query
(e.g. C<['UInt32', 'String', 'Nullable(DateTime)']>).

=item last_query_id

C<query_id> of the most recently dispatched query, or C<undef>. Set via
C<< { query_id => 'my-id' } >> in the settings hash of L</query>/L</insert>.

=item last_error_code

ClickHouse error code (integer) of the most recent server-side exception,
or C<0> if no error. The B<top-level> code is reported even when the
exception is a chain. Useful for distinguishing retryable errors (e.g.
C<202> = C<TOO_MANY_SIMULTANEOUS_QUERIES>) from permanent ones (C<60> =
C<UNKNOWN_TABLE>, C<516> = C<AUTHENTICATION_FAILED>).

=item last_totals

Arrayref of totals rows from the last query that used C<WITH TOTALS>,
or C<undef>. Native only.

=item last_extremes

Arrayref of extremes rows from the last native query, or C<undef>.

=item profile_rows_before_limit

Rows that would have been returned without C<LIMIT>. Useful for pagination
UIs. Native only.

=item profile_rows

Total rows processed by the last query (native ProfileInfo).

=item profile_bytes

Total bytes processed by the last query (native ProfileInfo).

=back

=head1 ALIASES

    q          -> query
    reconnect  -> reset
    disconnect -> finish

=head1 REQUIREMENTS

=over 4

=item * Perl 5.12 or newer

=item * L<EV> 4.11 or newer (event loop)

=item * zlib (required)

=item * OpenSSL (optional, for TLS; auto-detected at build time)

=item * liblz4 (optional, for native protocol compression; auto-detected)

=back

=head1 SEE ALSO

L<EV>, L<https://clickhouse.com/docs>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

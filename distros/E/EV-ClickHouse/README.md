# EV::ClickHouse

Async ClickHouse client for Perl using the EV event loop.

Implements both the ClickHouse HTTP and native TCP protocols directly in
XS — no external ClickHouse client library dependency.

## Features

- Async connect, query, insert via HTTP protocol (port 8123)
- Native TCP protocol (port 9000) with binary column-oriented data
- TabSeparated format parser with NULL/escape handling
- Gzip compression (HTTP) and LZ4 compression (native)
- Session management via session_id (HTTP)
- TLS/SSL support via OpenSSL (with `tls_skip_verify` for self-signed certs)
- Connection URI parsing (`clickhouse[+native]://user:pass@host:port/db`)
- Per-query and connection-level ClickHouse settings
- Parameterized queries (`params => { name => value }`)
- Auto-reconnect with exponential backoff
- Keepalive ping for idle native connections
- Graceful drain callback, query cancel, skip_pending
- Streaming results via `on_data` per-block callback (native)
- Raw HTTP response mode (returns body unparsed for CSV/JSON/Parquet)
- Opt-in decode of Date/DateTime, Decimal, Enum columns
- Named-rows mode (rows as hashrefs keyed by column name)
- Per-query `query_timeout` with automatic cancellation
- Insert from TSV string or arrayref of arrayrefs
- 30+ ClickHouse types: Int/UInt 8–256, Float, Bool, String, FixedString,
  Date/Date32/DateTime/DateTime64 with timezones, Decimal32/64/128, UUID,
  IPv4, IPv6, Enum8/16, Nullable, Array, Tuple, Map, LowCardinality (with
  cross-block dictionary), SimpleAggregateFunction, Nested, Nothing

## Synopsis

```perl
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host       => '127.0.0.1',
    port       => 8123,
    on_connect => sub {
        $ch->query("select * from system.one format TabSeparated", sub {
            my ($rows, $err) = @_;
            die $err if $err;
            print join(", ", @{$rows->[0]}), "\n";
            EV::break;
        });
    },
    on_error => sub { die $_[0] },
);

EV::run;
```

## Build

```
perl Makefile.PL
make
make test   # needs ClickHouse running
```

Set `TEST_CLICKHOUSE_HOST` and `TEST_CLICKHOUSE_PORT` (HTTP) or
`TEST_CLICKHOUSE_NATIVE_PORT` (native) environment variables if
ClickHouse is not on `127.0.0.1:8123`/`9000`.

## Dependencies

- EV (Perl module)
- zlib (`-lz`)
- OpenSSL (optional, for TLS)
- liblz4 (optional, for native protocol compression)

## License

Same terms as Perl itself.

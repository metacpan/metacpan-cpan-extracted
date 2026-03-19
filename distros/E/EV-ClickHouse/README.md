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
- TLS/SSL support via OpenSSL
- Connection reset, ping, finish

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

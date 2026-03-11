# EV::MariaDB

Async MariaDB/MySQL client for Perl using libmariadb and the EV event loop.

## Features

- Fully asynchronous connect, query, prepared statements
- Query pipelining via `mysql_send_query`/`mysql_read_query_result` (up to 64 in-flight)
- Prepared statements with automatic buffer sizing via max_length detection
- Row streaming via `query_stream` for large result sets
- Transactions: `commit`, `rollback`, `autocommit`
- Connection utilities: ping, reset, change_user, select_db, reset_connection, set_charset
- Graceful async close via `close_async`
- Manual parameter binding with `bind_params` and `send_long_data` for BLOBs
- Column metadata (field names) returned as optional third callback argument
- Multi-result set support

## Synopsis

```perl
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

# simple query
$m->query("select * from users", sub {
    my ($rows, $err, $fields) = @_;
    if ($err) { warn $err; return }
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
```

## Install

Requires EV and Alien::MariaDB (which finds or builds libmariadb).

```
cpanm EV Alien::MariaDB
perl Makefile.PL && make && make test
```

Set connection info for tests:

```
TEST_MARIADB_HOST=127.0.0.1 TEST_MARIADB_USER=root make test
# or via unix socket:
TEST_MARIADB_SOCKET=/var/run/mysqld/mysqld.sock make test
```

## Benchmark

500,000 queries against MariaDB 11.8 with ENGINE=MEMORY tables (no disk I/O), localhost unix socket. Compared to DBD::MariaDB 1.24 (synchronous DBI driver).

### SELECT (`select 1+1`)

| Method | q/s | us/q | vs DBD sync |
|---|--:|--:|--:|
| EV::MariaDB pipeline(64) | 121,033 | 8.3 | **2.4x** |
| EV::MariaDB prepared | 58,911 | 17.0 | 1.2x |
| EV::MariaDB sequential | 50,468 | 19.8 | 1.0x |
| DBD::MariaDB sync prepared | 52,828 | 18.9 | 1.1x |
| DBD::MariaDB sync | 49,857 | 20.1 | 1.0x |
| DBD::MariaDB async+EV | 49,437 | 20.2 | 1.0x |

### INSERT

| Method | q/s | us/q | vs DBD sync |
|---|--:|--:|--:|
| EV::MariaDB pipeline(64) | 78,781 | 12.7 | **1.8x** |
| EV::MariaDB prepared | 55,214 | 18.1 | 1.2x |
| DBD::MariaDB sync prepared | 55,996 | 17.9 | 1.3x |
| EV::MariaDB sequential | 44,380 | 22.5 | 1.0x |
| DBD::MariaDB sync | 44,684 | 22.4 | 1.0x |
| DBD::MariaDB async+EV | 42,145 | 23.7 | 0.9x |

### SELECT point lookup (hash-indexed MEMORY table)

| Method | q/s | us/q | vs DBD sync |
|---|--:|--:|--:|
| EV::MariaDB pipeline(64) | 50,004 | 20.0 | **1.6x** |
| EV::MariaDB prepared | 37,911 | 26.4 | 1.2x |
| DBD::MariaDB sync prepared | 36,813 | 27.2 | 1.2x |
| EV::MariaDB sequential | 30,640 | 32.6 | 1.0x |
| DBD::MariaDB sync | 30,778 | 32.5 | 1.0x |
| DBD::MariaDB async+EV | 30,005 | 33.3 | 1.0x |

Pipeline mode provides 1.6-2.4x throughput over sequential execution by batching up to 64 queries before reading results, eliminating round-trip latency.

## API

See `perldoc EV::MariaDB` for full documentation, including:

- `query($sql, $cb)` / `q` — execute SQL (callback receives `$rows`, `$err`, `$fields`)
- `query_stream($sql, $cb)` — stream rows one at a time for large result sets
- `prepare($sql, $cb)` / `prep` — prepare statement
- `execute($stmt, \@params, $cb)` — execute prepared statement
- `bind_params($stmt, \@params)` — manually bind parameters (synchronous)
- `send_long_data($stmt, $idx, $data, $cb)` — send BLOB/CLOB data in chunks
- `close_stmt($stmt, $cb)` — close prepared statement
- `close_async($cb)` — graceful async connection close
- `stmt_reset($stmt, $cb)` — reset prepared statement state
- `commit($cb)`, `rollback($cb)`, `autocommit($mode, $cb)` — transactions
- `ping($cb)`, `select_db($db, $cb)`, `change_user(...)` — utilities
- `set_charset($charset, $cb)` — change connection character set
- `reset_connection($cb)` — reset session state without reconnecting
- `reset` / `reconnect` — disconnect and reconnect
- `finish` / `disconnect` — close connection
- `skip_pending` — cancel all pending operations
- `escape($str)` — escape string for SQL
- `on_connect($cb)`, `on_error($cb)` — get/set handlers
- `lib_version`, `lib_info` — class methods for client library info

## License

Same terms as Perl itself.

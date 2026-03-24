# EV::Pg

Asynchronous PostgreSQL client for Perl using libpq and the EV event loop.

## Features

- Non-blocking queries via libpq async API
- Parameterized queries and prepared statements
- Pipeline mode for batched queries
- Single-row mode, chunked rows (libpq >= 17)
- COPY IN/OUT
- LISTEN/NOTIFY
- Cancel (sync and async, libpq >= 17)
- Structured error fields and result metadata
- Protocol tracing
- Connection introspection and reset
- Notice handling

## Synopsis

```perl
use v5.10;
use EV;
use EV::Pg;

my $pg = EV::Pg->new(
    conninfo   => 'dbname=mydb',
    on_error   => sub { die "PG error: $_[0]\n" },
);
$pg->on_connect(sub {
    $pg->query("select 1, 'hello'", sub {
        my ($rows, $err) = @_;
        die $err if $err;
        say $rows->[0][1];  # hello
        EV::break;
    });
});
EV::run;
```

## Parameterized queries

```perl
$pg->query_params(
    'select $1::int + $2::int',
    [10, 20],
    sub {
        my ($rows, $err) = @_;
        say $rows->[0][0];  # 30
    },
);
```

## Prepared statements

```perl
$pg->prepare('stmt', 'select $1::int', sub {
    $pg->query_prepared('stmt', [42], sub {
        my ($rows, $err) = @_;
        say $rows->[0][0];  # 42
    });
});
```

## Pipeline mode

```perl
use EV::Pg qw(:pipeline);

$pg->enter_pipeline;
for my $i (0 .. 999) {
    $pg->query_params('select $1::int', [$i], sub { ... });
}
$pg->pipeline_sync(sub {
    $pg->exit_pipeline;
});
```

## Callback convention

All query callbacks receive `($result)` on success, `(undef, $error)` on error:

- **SELECT**: `(\@rows)` where each row is an arrayref
- **INSERT/UPDATE/DELETE**: `($cmd_tuples)`
- **Describe**: `(\%meta)` with keys `nfields`, `nparams`; `fields` and `paramtypes` when non-zero
- **Error**: `(undef, $error_message)`
- **COPY**: `("COPY_IN")`, `("COPY_OUT")`, or `("COPY_BOTH")`
- **Pipeline sync**: `(1)`

## Installation

Requires [Alien::libpq](https://metacpan.org/pod/Alien::libpq) and EV.
Alien::libpq will use the system libpq if available, or build it from source.

```sh
cpanm EV::Pg
```

Or manually:

```sh
perl Makefile.PL
make
make test
make install
```

## Benchmark

500k queries over Unix socket, PostgreSQL 18, libpq 18:

| Workload | EV::Pg sequential | EV::Pg pipeline | DBD::Pg sync | DBD::Pg async+EV |
|----------|------------------:|----------------:|-------------:|-----------------:|
| SELECT   | 83,998 q/s | 144,939 q/s | 73,195 q/s | 65,966 q/s |
| INSERT   | 67,053 q/s | 85,701 q/s | 60,127 q/s | 58,329 q/s |
| UPSERT   | 37,360 q/s | 43,019 q/s | 40,278 q/s | 40,173 q/s |

EV::Pg sequential uses prepared statements (parse once, bind+execute per call).
Pipeline mode batches queries with `pipeline_sync` every 1000 queries.

## License

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# EV::Future

High-performance async control flow for Perl's EV event loop, implemented in XS.

## Functions

- `parallel(\@tasks, \&final_cb [, $unsafe])` - run all tasks concurrently
- `parallel_limit(\@tasks, $limit, \&final_cb [, $unsafe])` - concurrent with concurrency limit
- `series(\@tasks, \&final_cb [, $unsafe])` - run tasks sequentially
- `race(\@tasks, \&final_cb [, $unsafe])` - first task to finish wins; its args go to `final_cb`
- `parallel_map(\@items, \&worker, \&final_cb [, $unsafe])` - worker per item, concurrently
- `parallel_map_limit(\@items, \&worker, $limit, \&final_cb [, $unsafe])` - worker per item, with a limit
- `series_map(\@items, \&worker, \&final_cb [, $unsafe])` - worker per item, sequentially

Called in non-void context, each returns a handle supporting `cancel`, `pending` and `active`.

## Install

```bash
perl Makefile.PL && make && make test
```

Requires Perl 5.14+, EV 4.37+, and a C compiler.

## Benchmarks

1000 sync tasks x 5000 iterations (`bench/comparison.pl`; `race` is not covered by
that script, so it has no row here). Measured with EV 4.37, AnyEvent 7.17,
Future::XS 0.15, Promise::XS 0.21 and Future::Utils 0.52:

| | parallel | parallel_limit(10) | series |
|---|---:|---:|---:|
| EV::Future (unsafe) | 9,259 | 7,692 | 7,692 |
| EV::Future (safe) | 4,098 | 4,032 | 3,968 |
| AnyEvent cv | 1,563 | - | 4,717 |
| Future::XS | 1,563 | 624 | 1,241 |
| Promise::XS | 1,323 | - | 1,157 |

Safe mode adds per-task double-call protection and `G_EVAL`. Unsafe mode skips both, roughly doubling throughput.

## Examples

The `eg/` directory has runnable examples that need nothing but EV:

- `map_limit.pl` - a worker per item with a concurrency limit
- `series_map_pipeline.pl` - a sequential pipeline that stops at the first failure
- `cancel_progress.pl` - the handle: `pending`, `active` and early `cancel`
- `race_timeout.pl` - racing work against a timeout, and tearing the loser down

Alongside them, `curl_parallel.pl`, `redis_parallel.pl` and `etcd_series.pl`
show real clients (AnyEvent::YACurl, EV::Hiredis, EV::Etcd), and need those
modules and a reachable service.

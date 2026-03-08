# EV::Future

High-performance async control flow for Perl's EV event loop, implemented in XS.

## Functions

- `parallel(\@tasks, \&final_cb [, $unsafe])` - run all tasks concurrently
- `parallel_limit(\@tasks, $limit, \&final_cb [, $unsafe])` - concurrent with concurrency limit
- `series(\@tasks, \&final_cb [, $unsafe])` - run tasks sequentially

## Install

```bash
perl Makefile.PL && make && make test
```

Requires Perl 5.10+, EV 4.37+, and a C compiler.

## Benchmarks

1000 sync tasks x 5000 iterations:

| | parallel | parallel_limit(10) | series |
|---|---:|---:|---:|
| EV::Future (unsafe) | 4,386 | 4,673 | 5,000 |
| EV::Future (safe) | 2,262 | 2,688 | 2,591 |
| AnyEvent cv | 1,027 | - | 3,185 |
| Future::XS | 982 | 431 | 893 |
| Promise::XS | 32 | - | 809 |

Safe mode adds per-task double-call protection and `G_EVAL`. Unsafe mode skips both, roughly doubling throughput.

## Examples

See `eg/` directory for usage with AnyEvent::YACurl, EV::Hiredis, and EV::Etcd.

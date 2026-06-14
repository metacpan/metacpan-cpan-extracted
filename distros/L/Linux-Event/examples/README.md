# Linux::Event examples

These examples demonstrate the current Linux::Event API. The low-numbered
examples are ordered from basic loop features to more advanced composition
patterns. The 90-series files are manual benchmarks and regression runners.

## Basic and feature examples

- `01-after.pl` - relative timer
- `02-at.pl` - absolute monotonic timer deadline
- `03-watch-pipe.pl` - readiness watch on a pipe
- `04-watch-replace.pl` - replacing an existing watcher for the same file descriptor
- `05-watch-oneshot.pl` - one-shot watcher behavior
- `06-unwatch-safe.pl` - idempotent unwatch and watcher cancellation
- `07-signal.pl` - signalfd signal delivery
- `08-waker-thread.pl` - eventfd wakeup from another thread
- `09-waker-fork-pipe.pl` - eventfd wakeup with a forked producer and separate payload pipe
- `10-pid.pl` - pidfd child exit notification

## Manual benchmarks and regression runners

- `90-bench-oneshot.pl` - pipe readability throughput benchmark
- `91-stress-oneshot-edge-safe.pl` - edge-triggered one-shot stress runner
- `93-regress-stop-no-backend-wait.pl` - stop-before-backend-wait regression runner
- `94-regress-epoll-oneshot-rearm.pl` - Linux::Event backend one-shot rearm regression runner

Run all examples with:

```sh
perl examples/all.pl
```

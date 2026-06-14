# Linux::Event reactor benchmarks

This directory contains the benchmark harness used to compare Linux::Event
reactor performance across local builds.

The benchmark is intentionally outside `t/`. It is for performance tracking, not
release correctness.

## Normal workflow

Generate or refresh a local baseline:

```sh
perl bench/run-reactor-bench.pl phase0 --backend pp
```

Benchmark the current optimized build:

```sh
perl bench/run-reactor-bench.pl phase012 --backend xs
```

Compare two recorded runs:

```sh
perl bench/run-reactor-bench.pl compare phase0 phase012
```

The phase label is only a result-file prefix. Any label matching `phase...` is
accepted. By convention, `phase0` is the local baseline and non-`phase0` labels
use the XS backend unless `--backend` is supplied.

## Output files

A phase run overwrites result files for that phase in `bench/results/`:

```text
bench/results/<phase>-echo.json
bench/results/<phase>-pipe.json
bench/results/<phase>-watchers.json
bench/results/<phase>-callbacks.json
bench/results/<phase>-timers.json
```

No benchmark JSON results are shipped in the release archive.

## Backend selection

By default:

```text
phase0        -> pp backend label
other phases  -> xs backend label
```

Both labels currently construct `Linux::Event::Backend::Epoll`. The labels exist
so result JSON can distinguish a local baseline from an optimized build without
changing the public backend class name.

You can override the label when needed:

```sh
perl bench/run-reactor-bench.pl phase012 --backend pp
perl bench/run-reactor-bench.pl phase012 --backend xs
```

## Prerequisite check

Before running performance scenarios on a fresh checkout, verify that the
benchmark runtime modules are loadable:

```sh
perl bench/check-prereqs.pl
```

The checker only reports whether the benchmark runtime modules can be loaded
from your current `PERL5LIB` / installed Perl.

## Standard suite

The phase command runs these scenarios automatically:

| Scenario | Result file suffix | Measures |
| --- | --- | --- |
| `echo_tcp` | `echo` | localhost TCP accept/read/write/dispatch throughput |
| `pipe_churn` | `pipe` | raw readiness processing using a watched pipe |
| `watcher_churn` | `watchers` | watch/cancel churn, fd registry work, and `epoll_ctl` overhead |
| `callback_storm` | `callbacks` | many watched fds becoming ready and invoking minimal Perl callbacks |
| `timer_heap` | `timers` | timer scheduling and firing overhead |

Current suite defaults:

```text
echo_tcp:       clients 1,10,50,100; 1000 messages/client; 64-byte messages
pipe_churn:     1,000,000 real pipe readiness events
watcher_churn:  100,000 watchers
callback_storm: 1,000,000 events across up to 1000 watched pipe fds
timer_heap:     50,000 timers
```

`callback_storm` asks for 1000 watched pipe pairs by default. If the process
open-file limit is too low, it automatically uses as many pipe pairs as it can
create instead of aborting the full phase run. The JSON includes both
`requested_fds` and actual `fds`, plus `fd_cap_hit` when the fallback happened.

`pipe_churn` counts real readiness callbacks, not bulk bytes. It uses one byte
per callback and re-arms the same pipe after each callback.

## Expert one-off mode

The simple phase workflow should be enough most of the time, but manual mode is
available for focused experiments.

Run one scenario manually:

```sh
perl bench/run-reactor-bench.pl \
  --backend xs \
  --phase manual \
  --scenario echo_tcp \
  --clients 1,10,50,100 \
  --messages 1000 \
  --message-size 64 \
  --json bench/results/manual-echo.json
```

Run callback storm manually:

```sh
perl bench/run-reactor-bench.pl \
  --backend xs \
  --phase manual \
  --scenario callback_storm \
  --events 1000000 \
  --fds 1000 \
  --json bench/results/manual-callbacks.json
```

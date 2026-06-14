# Benchmark validation notes

This checkout includes the reactor benchmark harness under `bench/`.

Validated in this packaging pass:

```sh
perl -c bench/run-reactor-bench.pl
perl -c bench/lib/Linux/Event/Bench.pm
perl -c bench/check-prereqs.pl
perl -c bench/scenarios/pipe_churn.pl
perl -c bench/scenarios/callback_storm.pl
perl -c bench/scenarios/timer_heap.pl
perl -c bench/scenarios/watcher_churn.pl
perl -c bench/scenarios/echo_tcp.pl
```

No benchmark result JSON files are included. Generate your local baseline and a
current-build run with:

```sh
perl bench/check-prereqs.pl
perl bench/run-reactor-bench.pl phase0 --backend pp
perl bench/run-reactor-bench.pl phase012 --backend xs
perl bench/run-reactor-bench.pl compare phase0 phase012
```

# Logging, events, health, and resource monitoring

> Read when: setting up operational visibility or finding unexpected disk/memory growth.

Send application logs to stdout/stderr with timestamps/correlation fields at the application or collector layer. Choose a logging driver and retention policy deliberately. Docker recommends the `local` driver for many non-Kubernetes uses because it includes rotation; the default `json-file` configuration can grow without an appropriate rotation policy.

Changing daemon logging defaults applies to newly created containers, not necessarily existing ones. Inspect each container's actual logging configuration. Some drivers require dual logging/cache behavior for `docker logs` access; test the read path and log-shipping failure behavior.

## Build a small useful dashboard

Track service availability, restart rate, unhealthy state duration, CPU throttling, memory pressure, disk bytes/inodes, log growth, request latency/error rate, and backup freshness. A low CPU graph does not exclude disk or network bottlenecks. A healthy container does not prove application correctness.

Events help correlate create/start/die/OOM/health transitions but are not a durable audit log. The Engine only retains a bounded recent event history. Reconnect collectors and reconcile current state after gaps. Persist your own audit/metrics externally with an explicit retention policy.

Container API memory counters and CLI display values can differ because the CLI adjusts Linux cache accounting. Do not compare them as though they were the same metric. Distinguish cumulative counters from instantaneous rates, and reset rate calculations across container restarts.

## Alert design

Alert on actionable symptoms with a responsible owner: sustained failing requests, repeated restarts, insufficient free storage, failed restores, or inability to pull a required digest. Avoid paging for every short-lived unhealthy transition during an expected startup window. Keep secrets, full environment dumps, and raw API auth headers out of telemetry.

## Primary sources

- [Logging drivers](https://docs.docker.com/engine/logging/configure/)
- [Docker events](https://docs.docker.com/reference/cli/docker/system/events/)
- [Container stats](https://docs.docker.com/reference/cli/docker/container/stats/)
- [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)

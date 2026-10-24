# Resources, devices, replicas, and deployment semantics

> Read when: limiting load, exposing accelerators, or scaling a service.

Budget memory, CPU, process count, ephemeral disk/log growth, connections, and shared service capacity. A CPU quota is a cap, not a reservation of physical cores. A memory limit below the application's working set produces failure rather than optimization. Include cache, JVM/runtime heaps, worker count, and startup spikes in the budget.

For a local Compose project, use fields supported by the actual implementation and inspect the resulting `HostConfig`. Do not assert that every `deploy:` field is honored or that all are ignored: resource/device portions can be implemented while distributed placement/update behavior still requires an orchestrator.

```yaml
services:
  app:
    image: "${APP_IMAGE:?Set APP_IMAGE}"
    cpus: 1.0
    mem_limit: 512m
    pids_limit: 128
    init: true
```

These numbers are illustrative, not workload sizing. Verify `docker inspect` plus measured behavior. Account for rootless cgroup delegation and platform differences. GPU/device declarations require compatible host drivers/runtime integration and explicit device selection; YAML alone cannot provide unavailable hardware. Treat raw device access as a security decision.

## Scaling safely

`up --scale app=N` creates replicas on the target Engine; it does not create a multi-node cluster. Fixed `container_name` prevents normal scaling. Fixed host port bindings can collide. A load-balancing/reverse-proxy design and stateless request handling are separate requirements.

A shared writable volume is not a concurrency-control mechanism. Database migration jobs and singleton background tasks need leader election, locking, or separate placement. Test concurrent replicas against the actual data backend and connection budget.

## Acceptance evidence

Measure latency and error rate under bounded load, memory high-water mark, throttling, restart count, and shutdown behavior. Repeat with one instance unavailable. Confirm that an explicit cap is enforced, then separately check whether it is adequate. Prefer a smaller known-safe replica count to automatically scaling into database exhaustion.

## Primary sources

- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)
- [Rootless mode](https://docs.docker.com/engine/security/rootless/)
- [Container stats](https://docs.docker.com/reference/cli/docker/container/stats/)

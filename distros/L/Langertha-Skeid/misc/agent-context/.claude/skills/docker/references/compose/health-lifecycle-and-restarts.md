# Health, dependency conditions, restarts, and shutdown

> Read when: a stack starts too soon, remains unhealthy, or loses work during stop.

`depends_on` orders dependency startup. Short syntax waits for the dependency to be running, not application-ready. Long syntax can require `service_healthy` or `service_completed_successfully`. A health check must exist and test the actual readiness condition; a process existing or a port accepting connections may be insufficient.

```yaml
# Fragment: app and db image/configuration must be supplied by the project.
services:
  app:
    depends_on:
      db:
        condition: service_healthy
        restart: true
```

The nested `restart: true` concerns explicit Compose-driven dependency updates/restarts. It is not the container-level restart policy and does not propagate every crash/restart from the daemon.

## Readiness is not self-healing

An unhealthy container is not automatically restarted by ordinary Docker restart policies. Those policies react to process exit and related daemon lifecycle rules. Nor does Compose continuously stop downstream services when a dependency later becomes unhealthy. Applications still need reconnect, bounded retry, backoff, and useful degraded-state behavior.

Keep probes cheap and deterministic. A probe must use tools present in the final image. Avoid installing a large package set solely for a curl health check if the application runtime can perform it. Never place credentials in visible probe command arguments or logs. Distinguish startup grace, interval, timeout, and retry count.

## Shutdown and exit evidence

Exec-form entrypoints, signal handling, optional `init: true`, and an appropriate `stop_grace_period` work together. Verify the application flushes data and stops accepting work before forced termination. A shell wrapper without signal forwarding can obscure the real process, but not every shell-form command always swallows signals.

Exit 137 means SIGKILL-style termination in the conventional exit encoding; it is not sufficient evidence of OOM. Check `State.OOMKilled`, daemon/kernel evidence, manual kills, shutdown timeout, and timestamp correlation. Save logs and inspect data before recreating a failing container.

## Primary sources

- [Compose startup and shutdown](https://docs.docker.com/compose/how-tos/startup-order/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)

# Evidence-first diagnostic ladder

> Read when: a container is broken, slow, unreachable, or repeatedly restarting.

Begin by recording target context/project, time window, symptom, recent changes, and expected behavior. Separate “container running”, “healthy”, “application responding”, and “correct result.” Do not recreate the failing container before collecting its state unless recovery urgency explicitly outweighs evidence preservation.

```sh
docker compose ps -a
docker compose logs --tail 200 --timestamps app
docker inspect CONTAINER_ID --format '{{json .State}}'
docker stats --no-stream
docker system df
```

Logs and state may contain sensitive values; inspect locally and redact before sharing. Narrow `inspect` to the fields needed instead of dumping environment, labels, mount paths, and credentials indiscriminately.

## Classify the failure

| Symptom | First discriminating evidence |
|---|---|
| Never starts | Exit code, startup error, command/user/mount permissions |
| Repeated restart | State timestamps, restart policy, first application failure |
| Healthy but unreachable | Bind address, shared network, container port, host publication |
| Exit 137 | OOMKilled plus kernel/daemon timing; other SIGKILL sources |
| Disk full | Filesystem bytes and inodes; logs, volumes, images, build cache separately |
| Slow | Application latency, CPU throttling, memory pressure, disk/network wait |
| Wrong configuration | Exact model inputs and selected non-secret runtime values |

For networking, test from the failing namespace. For builds, inspect the actual BuildKit worker. For registry pulls, examine daemon/runtime logs and registry endpoint/trust; a successful request from inside a pod may be irrelevant.

## Make one controlled change

State the hypothesis and expected observation before changing anything. Prefer a reversible, narrow action. Re-run the same check, compare with the baseline, and preserve the result. A restart that temporarily improves latency does not identify the cause. A successful pull does not prove mirror use. Cleanup that frees disk does not explain why retention failed.

The companion `scripts/collect-basics.sh` intentionally collects bounded read-only summaries and avoids full inspect/config dumps. It still requires review before sharing output.

## Primary sources

- [Container stats](https://docs.docker.com/reference/cli/docker/container/stats/)
- [Docker events](https://docs.docker.com/reference/cli/docker/system/events/)
- [Logging drivers](https://docs.docker.com/engine/logging/configure/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)

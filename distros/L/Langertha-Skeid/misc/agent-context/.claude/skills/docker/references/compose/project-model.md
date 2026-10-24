# Compose model, project identity, and command selection

> Read when: creating a stack, handling two checkouts, or explaining what a command will change.

A Compose project is the namespace in which service instances and managed networks/volumes are reconciled by a CLI invocation. It is not a background scheduler. Keep a deliberate project identity for development, tests, and production. Explicit `-p` is useful in automation; avoid globally fixed `container_name` entries because they defeat independent copies and service scaling.

```sh
docker compose -p app-test -f compose.yaml config -q
docker compose -p app-test -f compose.yaml config --services
docker compose -p app-test -f compose.yaml ps -a
```

Use the same context, working directory, file order, env files, profiles, and project name for planning and applying. Rendering one model and deploying another is a preventable source of mistakes. `config` can reveal interpolated secrets; do not paste its full output into tickets.

## Choose the operation

| Operation | Intended role |
|---|---|
| `up` | Create/reconcile services; changed config can cause recreation |
| `start` | Start existing stopped containers, not apply a new model |
| `restart` | Restart existing containers; does not apply new environment/config |
| `run --rm SERVICE COMMAND` | One-off container based on a service; not identical to starting the service |
| `exec SERVICE COMMAND` | Execute inside an already running service container |
| `stop` | Stop while retaining containers |
| `down` | Remove project containers and managed networks; volume deletion is separate |

A configuration change is normally applied with `up -d`; `--force-recreate` is a deliberate override, not mandatory for all environment edits. An updated mutable tag may also require an explicit pull policy or `pull` before reconciliation. For production, prefer an intentional digest change.

Do not automatically run `down` before every deployment: it introduces an outage and destroys useful runtime evidence. Do not attach `-v` to generic cleanup. Read the storage reference before any volume deletion.

## Primary sources

- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Compose in production](https://docs.docker.com/compose/how-tos/production/)
- [Compose history and versions](https://docs.docker.com/compose/intro/history/)

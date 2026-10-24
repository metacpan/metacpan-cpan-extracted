# Compose Watch, bind mounts, and development workflows

> Read when: creating a fast edit/test loop without shipping development behavior to production.

Choose one primary synchronization strategy per path. A bind mount shares the host path at runtime; Watch can sync changes, rebuild images, or trigger supported restart/exec actions. Combining both blindly can obscure image content, overwrite dependencies, and cause repeated rebuilds.

Use `sync` for interpreted source when the application reloads itself. Use `sync+restart` when copied code requires a process restart. Rebuild when dependency manifests, compiler inputs, or Dockerfiles change. Later Watch actions are version-gated; verify the installed Develop specification support.

The target filesystem must be writable by the container user, and required basic utilities must exist. Exclude virtual environments, dependency directories, editor files, generated outputs, and secret files. Host-native dependencies may be incompatible with the container OS/architecture.

## Workflow

```sh
docker compose -f compose.yaml -f compose.dev.yaml config -q
docker compose -f compose.yaml -f compose.dev.yaml up --watch
```

These are explicit file names, not automatic defaults. Confirm the project actually provides them. A file watcher running on a developer's host does not make remote runtime bind mounts work; identify the synchronization actor and destination.

## Boundary test

After introducing Watch, verify initial content, a normal source edit, deletion/rename, a dependency change, and permissions after rebuild. Ensure watchers do not loop on generated files. Then render the production model and assert that it contains neither development bind mounts nor unwanted debug publications. Debug endpoints must not be assumed harmless because they were originally intended for localhost.

Desktop filesystem sharing can have different performance from native Linux. Measure the project on its actual storage path. Keep Linux development workspaces on the platform-recommended filesystem rather than moving data based on a generic “containers are slow” diagnosis.

## Primary sources

- [Compose Watch](https://docs.docker.com/compose/how-tos/file-watch/)
- [Compose Develop Specification](https://docs.docker.com/reference/compose-file/develop/)
- [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)

# Contexts and remote-host operation

> Read when: working over SSH, on multiple daemons, or with an SDK that disagrees with the CLI.

## Select the target explicitly

```sh
docker context ls
docker context inspect YOUR_CONTEXT
docker --context YOUR_CONTEXT version
docker --context YOUR_CONTEXT compose -p YOUR_PROJECT ps
```

For CLI automation, prefer an explicit context flag or a deliberately controlled environment. Log the selected context and server identity before modifying anything. A global `docker context use` changes subsequent terminal behavior and is a poor hidden prerequisite for parallel jobs.

SSH contexts reuse SSH authentication but still grant the remote user's Docker permissions. Mutual TLS is another remote-access option. Neither turns a full daemon API into a tenant-safe endpoint. Do not fix connectivity by exposing an unauthenticated TCP daemon.

## Paths and credentials

A local `./data:/data` binding in a Compose model is interpreted against the daemon's filesystem once resolved. Uploading Compose YAML to a remote daemon does not upload that source directory. Choose a real remote path, named volume, or image-baked content. `build:` can transfer a local context; that is a different operation.

Registry credentials are client/build tooling inputs, while registry networking and trust often belong to the worker or daemon. Keep separate inventories for Docker CLI config, Engine certificates, BuildKit config, and application trust stores.

## When a program disagrees

Do not assume every SDK resolves Docker contexts or honors every `DOCKER_*` variable. Compare the endpoint the program actually opens with the endpoint from context inspection. Pass endpoint/TLS settings explicitly through the SDK's supported configuration interface, or choose a library with documented context support. Never parse a context's metadata directory layout as a stable public API without a compatibility policy.

Verify with read-only commands first; then use a uniquely named disposable container to prove that the intended server receives operations. Do not use existing production containers as connectivity probes.

## Primary sources

- [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/)
- [Protect the daemon socket](https://docs.docker.com/engine/security/protect-access/)
- [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)

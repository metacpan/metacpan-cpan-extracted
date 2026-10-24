# Execution model and responsibility boundaries

> Read when: an operation succeeds on one host but not another, or ownership of state is unclear.

Think in five places: CLI host, Engine host, BuildKit worker, registry endpoint, and application container. They can all be different machines. The CLI selects a context and sends a request; the daemon owns containers and mounts; the builder owns build execution and cache; the registry distributes content. An application's network namespace is not any of those hosts.

A remote bind mount refers to the **daemon host's path**, while a normal local build context is sent from the build client to the builder. A private CA trusted by the developer's browser is not automatically trusted by the daemon, builder, or application image. Resolve “file missing”, “cannot connect”, and “certificate unknown” by identifying which of these actors performed the operation.

Images are content-addressed objects with a configuration and layers. Containers add mutable runtime state. A tag is a mutable reference, not a release identity. A volume is not part of the image, and replacing a container does not upgrade its database format. `save/load` handles image artifacts; `export/import` handles a container filesystem and does not preserve the same image metadata or mounted-volume data.

## Design worksheet

For each stateful component, write: owner, data path, lifecycle, credential source, network reachability, backup mechanism, and recovery target. For each build, write: context root, worker, cache owner, output destination, platform set, and exact release digest.

Use Engine/Compose for host workloads, Buildx/Bake for build orchestration, `docker-engine-api` for direct HTTP clients, and `docker-registry` for registry operation or wire protocol. Compose is not a distributed desired-state controller. Swarm and Kubernetes have their own scheduling and readiness contracts; do not infer them from a Dockerfile health check.

## Primary sources

- [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/)
- [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [Volumes](https://docs.docker.com/engine/storage/volumes/)
- [Engine API compatibility](https://docs.docker.com/reference/api/engine/)

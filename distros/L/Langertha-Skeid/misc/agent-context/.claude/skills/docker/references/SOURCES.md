# Primary-source register

Documentation review: **2026-10-09**. The references in this skill link to the sources relevant to each topic. This register is for maintenance; agents should not fetch every source on every task.

Dynamic documentation and release branches can change. Revalidate exact release-dependent options before implementation. Pinned implementation sources describe that release, not all compatible products. No upstream manual or complete source repository is bundled. Operational checklists, examples, and decision guidance are authored additions.

| Source | Evidence scope |
|---|---|
| [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) | Maintained primary documentation/source |
| [Building best practices](https://docs.docker.com/build/building/best-practices/) | Maintained primary documentation/source |
| [Build context](https://docs.docker.com/build/concepts/context/) | Maintained primary documentation/source |
| [Cache invalidation](https://docs.docker.com/build/cache/invalidation/) | Maintained primary documentation/source |
| [Cache optimization](https://docs.docker.com/build/cache/optimize/) | Maintained primary documentation/source |
| [Cache backends](https://docs.docker.com/build/cache/backends/) | Maintained primary documentation/source |
| [Build secrets](https://docs.docker.com/build/building/secrets/) | Maintained primary documentation/source |
| [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/) | Maintained primary documentation/source |
| [Build attestations](https://docs.docker.com/build/metadata/attestations/) | Maintained primary documentation/source |
| [Buildx Bake](https://docs.docker.com/build/bake/) | Maintained primary documentation/source |
| [Compose history and versions](https://docs.docker.com/compose/intro/history/) | Maintained primary documentation/source |
| [Compose services reference](https://docs.docker.com/reference/compose-file/services/) | Maintained primary documentation/source |
| [Compose interpolation sources](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/) | Maintained primary documentation/source |
| [Container environment precedence](https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/) | Maintained primary documentation/source |
| [Setting container environment variables](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/) | Maintained primary documentation/source |
| [Compose merge rules](https://docs.docker.com/reference/compose-file/merge/) | Maintained primary documentation/source |
| [Multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/) | Maintained primary documentation/source |
| [Compose include](https://docs.docker.com/reference/compose-file/include/) | Maintained primary documentation/source |
| [Compose profiles](https://docs.docker.com/compose/how-tos/profiles/) | Maintained primary documentation/source |
| [Compose startup and shutdown](https://docs.docker.com/compose/how-tos/startup-order/) | Maintained primary documentation/source |
| [Compose Watch](https://docs.docker.com/compose/how-tos/file-watch/) | Maintained primary documentation/source |
| [Compose Develop Specification](https://docs.docker.com/reference/compose-file/develop/) | Maintained primary documentation/source |
| [Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/) | Maintained primary documentation/source |
| [Compose in production](https://docs.docker.com/compose/how-tos/production/) | Maintained primary documentation/source |
| [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/) | Maintained primary documentation/source |
| [Daemon configuration and data directories](https://docs.docker.com/engine/daemon/) | Maintained primary documentation/source |
| [Docker networking](https://docs.docker.com/engine/network/) | Maintained primary documentation/source |
| [Packet filtering and firewalls](https://docs.docker.com/engine/network/packet-filtering-firewalls/) | Maintained primary documentation/source |
| [Volumes](https://docs.docker.com/engine/storage/volumes/) | Maintained primary documentation/source |
| [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/) | Maintained primary documentation/source |
| [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/) | Maintained primary documentation/source |
| [Logging drivers](https://docs.docker.com/engine/logging/configure/) | Maintained primary documentation/source |
| [Protect the daemon socket](https://docs.docker.com/engine/security/protect-access/) | Maintained primary documentation/source |
| [Rootless mode](https://docs.docker.com/engine/security/rootless/) | Maintained primary documentation/source |
| [Docker events](https://docs.docker.com/reference/cli/docker/system/events/) | Maintained primary documentation/source |
| [Container stats](https://docs.docker.com/reference/cli/docker/container/stats/) | Maintained primary documentation/source |
| [Engine API compatibility](https://docs.docker.com/reference/api/engine/) | Maintained primary documentation/source |

## Maintenance procedure

When updating a claim, check the target product release and primary reference, update its feature gate and examples together, and add a regression test where practical. Record an integration result separately from a documentation review. If documentation and measured behavior disagree, preserve the discrepancy and scope the claim; do not silently choose the more convenient interpretation.

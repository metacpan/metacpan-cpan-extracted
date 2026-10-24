# docker: reference index

Read [the skill entrypoint](../SKILL.md) first. Follow only the links needed for the task. These are on-demand reference files, not instructions to load the whole directory.

## Build

| Reference | Read when |
|---|---|
| [Bake and build orchestration boundaries](build/bake-and-build-orchestration.md) | multiple images, targets, or CI parameter sets need a shared build definition. |
| [Cache design, invalidation, and CI ownership](build/cache-and-ci.md) | builds are slow, unexpectedly stale, or share caches across projects. |
| [Build contexts, ignore rules, and remote inputs](build/contexts-and-ignore.md) | a build sends too much data, cannot COPY a file, or risks exposing credentials. |
| [Dockerfile design and runtime contracts](build/dockerfile-design.md) | writing or reviewing an image definition. |
| [Multi-platform images and output selection](build/multi-platform.md) | building for amd64/arm64 or debugging a missing or wrong-platform image. |
| [Build secrets and SSH access](build/secrets-and-ssh.md) | a build downloads private dependencies or needs a private repository. |
| [Release identity, SBOMs, provenance, and promotion](build/supply-chain-and-releases.md) | publishing images or establishing a reproducible release process. |

## Compose

| Reference | Read when |
|---|---|
| [Compose CI, production deployment, and rollback](compose/ci-deploy-and-rollback.md) | designing a release pipeline or operating a single-host production stack. |
| [Compose Watch, bind mounts, and development workflows](compose/development-watch-and-debug.md) | creating a fast edit/test loop without shipping development behavior to production. |
| [Health, dependency conditions, restarts, and shutdown](compose/health-lifecycle-and-restarts.md) | a stack starts too soon, remains unhealthy, or loses work during stop. |
| [Compose include and genuine module boundaries](compose/include-and-modularization.md) | a stack should be split into reusable subprojects with their own paths. |
| [Interpolation versus container environment](compose/interpolation-and-environment.md) | an environment value is wrong, missing, or different between config and runtime. |
| [Merge, overrides, extension fields, and fragments](compose/merge-overrides-and-fragments.md) | splitting development/production settings or removing an inherited port/mount. |
| [Compose networking and reachability](compose/networks-and-service-discovery.md) | one service cannot reach another or a port is exposed unexpectedly. |
| [Profiles, optional services, and one-off jobs](compose/profiles-and-jobs.md) | debug tools, migrations, test runners, or optional services are involved. |
| [Compose model, project identity, and command selection](compose/project-model.md) | creating a stack, handling two checkouts, or explaining what a command will change. |
| [Resources, devices, replicas, and deployment semantics](compose/resources-and-scaling.md) | limiting load, exposing accelerators, or scaling a service. |
| [Runtime secrets, configs, and trust boundaries](compose/secrets-configs-and-trust.md) | distributing credentials or configuration to Compose services. |
| [Compose storage, ownership, and persistence](compose/volumes-and-permissions.md) | choosing mounts, changing image versions, or debugging missing data/permission failures. |

## Concepts

| Reference | Read when |
|---|---|
| [Contexts and remote-host operation](concepts/contexts-and-remote-hosts.md) | working over SSH, on multiple daemons, or with an SDK that disagrees with the CLI. |
| [Execution model and responsibility boundaries](concepts/execution-model.md) | an operation succeeds on one host but not another, or ownership of state is unclear. |

## Operations

| Reference | Read when |
|---|---|
| [Application-aware backup and disaster recovery](operations/backup-and-disaster-recovery.md) | protecting named volumes or preparing an upgrade/recovery test. |
| [Daemon storage, disk accounting, and safe cleanup](operations/daemon-storage-and-cleanup.md) | moving Docker data or reclaiming space. |
| [Evidence-first diagnostic ladder](operations/diagnostic-ladder.md) | a container is broken, slow, unreachable, or repeatedly restarting. |
| [Logging, events, health, and resource monitoring](operations/logging-and-monitoring.md) | setting up operational visibility or finding unexpected disk/memory growth. |
| [Rootless, Docker Desktop, Windows, and Linux differences](operations/rootless-desktop-and-platforms.md) | moving a stack between a Linux server and a developer workstation. |
| [Hardening and agent/CI access to Docker](operations/security-and-agent-access.md) | giving an agent, runner, or application Docker control. |

## Start Here

| Reference | Read when |
|---|---|
| [Versions, capabilities, and evidence](versions-and-capabilities.md) | choosing syntax, upgrading a host, or moving examples between machines. |

## Maintenance

Read the [source register](SOURCES.md) for upstream verification.

The [Compose sub-index](compose/INDEX.md) collects its reference leaves and example entrypoints.

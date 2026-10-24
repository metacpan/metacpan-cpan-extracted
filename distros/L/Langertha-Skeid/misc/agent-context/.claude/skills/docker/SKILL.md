---
name: docker
description: "Use when designing, building, securing, debugging, or operating Docker images and Compose stacks: Dockerfiles, BuildKit/buildx/Bake, caching, multi-platform builds, Compose include/overrides/profiles/Watch, networking, volumes, readiness, deployment, or recovery. Load only the task-specific references."
user-invocable: true
---

# Docker and Compose

A decision and operations skill for Docker images, local/remote Engines, and Compose applications. Keep this entrypoint small; use the reference files for implementation details. Documentation review: **2026-10-09**. Recheck release-dependent behavior against the installed CLI, builder, daemon, and platform.

## Begin with the target, not a command

Establish the requested outcome, target context/host, operating system and rootless/Desktop mode, project name, Compose files/profiles, builder, image identity, and persistent data. Separate a build problem from a model-rendering problem, a runtime problem, and a registry problem. Never assume that the local shell and daemon share a filesystem.

Read [versions and capabilities](references/versions-and-capabilities.md) for new features or compatibility questions. For unfamiliar scope, read the [execution model](references/concepts/execution-model.md). Do not read every reference by default.

## Load by task

| Task or symptom | Read first | Expand only as needed |
|---|---|---|
| Slow, oversized, or unreliable builds | [Dockerfile design](references/build/dockerfile-design.md) | [Contexts](references/build/contexts-and-ignore.md), [cache and CI](references/build/cache-and-ci.md) |
| Build credentials or private dependencies | [Secrets and SSH](references/build/secrets-and-ssh.md) | [Supply chain](references/build/supply-chain-and-releases.md) |
| Architecture mismatch or build orchestration | [Multi-platform](references/build/multi-platform.md) | [Bake](references/build/bake-and-build-orchestration.md) |
| New Compose stack or command choice | [Project model](references/compose/project-model.md) | [Compose index](references/compose/INDEX.md) |
| Wrong environment value | [Interpolation and environment](references/compose/interpolation-and-environment.md) | [Secrets and configs](references/compose/secrets-configs-and-trust.md) |
| Split files, shared modules, or dev/prod variants | [Merge and fragments](references/compose/merge-overrides-and-fragments.md) | [Include](references/compose/include-and-modularization.md) |
| Readiness, dependencies, migrations, or unexpected restart | [Health and lifecycle](references/compose/health-lifecycle-and-restarts.md) | [Profiles and jobs](references/compose/profiles-and-jobs.md) |
| Connection refused or wrong exposure | [Networks](references/compose/networks-and-service-discovery.md) | [Contexts/remote hosts](references/concepts/contexts-and-remote-hosts.md) |
| Lost data or permission denied | [Volumes](references/compose/volumes-and-permissions.md) | [Backup and recovery](references/operations/backup-and-disaster-recovery.md) |
| Development feedback or live source updates | [Watch and debug](references/compose/development-watch-and-debug.md) | [Build cache](references/build/cache-and-ci.md) |
| High load, scaling, or OOM | [Resources and scaling](references/compose/resources-and-scaling.md) | [Logging/monitoring](references/operations/logging-and-monitoring.md) |
| Release, CI, deployment, or rollback | [Deploy and rollback](references/compose/ci-deploy-and-rollback.md) | [Image release identity](references/build/supply-chain-and-releases.md) |
| Incident or unexplained behavior | [Diagnostic ladder](references/operations/diagnostic-ladder.md) | [Daemon/storage](references/operations/daemon-storage-and-cleanup.md) |
| Agent access or host hardening | [Security and agent access](references/operations/security-and-agent-access.md) | [Rootless/Desktop/platforms](references/operations/rootless-desktop-and-platforms.md) |

## Operating rules

Start with non-mutating evidence. Before changing state, identify the exact context, project, resource ownership, expected impact, and recovery path. Treat socket access and build execution as privileged capabilities; a read-only socket mount is not a read-only API.

Render the intended Compose model before applying it. Interpolation sources are not automatically container environment variables. Readiness is not creation order, health status is not automatic repair, and restarting a container is not the same as applying changed configuration. Verify effective settings instead of trusting a successful command alone.

Never place secrets in image layers or unreviewed logs. Prefer build secret mounts and runtime secret files where supported. Do not infer production suitability from a teaching example. Image tags and sample resource budgets are not permanent deployment policy.

Do not run broad prune, volume deletion, `down -v`, or destructive database migration without explicit scope, authorization, and recovery evidence. Preserve incident evidence before recreating containers.

## Examples and output

The [modular Compose lab](examples/compose-lab/README.md) includes a small HTTP service, its healthcheck, a helper include, Watch override, and explicit port replacement. The [environment fixture](examples/environment/README.md) demonstrates two-stage environment handling; the [lifecycle fixture](examples/lifecycle/README.md) demonstrates health and one-off completion dependencies. [collect-basics.sh](scripts/collect-basics.sh) collects selected read-only CLI evidence.

For a proposed change, report target/version assumptions, selected references, exact files/commands, validation, expected effect, and rollback. For an incident, report evidence, ranked hypotheses, the next discriminating check, and the least destructive repair. State what was tested and what remains unverified.

Use sibling skill `docker-engine-api` for direct HTTP clients and `docker-registry` for registry/mirror operation. They are optional, not hidden installation dependencies. The [full index](references/INDEX.md) and [source register](references/SOURCES.md) provide deeper navigation.

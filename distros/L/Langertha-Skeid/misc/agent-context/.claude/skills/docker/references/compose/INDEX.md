# Compose reference map

Choose the smallest relevant set. Start with project identity for a new stack; use environment, merge/include, and lifecycle as separate concepts. This is a navigation file, not a Compose file and not an executable include directive.

| Reference | Read when |
|---|---|
| [Compose CI, production deployment, and rollback](ci-deploy-and-rollback.md) | designing a release pipeline or operating a single-host production stack. |
| [Compose Watch, bind mounts, and development workflows](development-watch-and-debug.md) | creating a fast edit/test loop without shipping development behavior to production. |
| [Health, dependency conditions, restarts, and shutdown](health-lifecycle-and-restarts.md) | a stack starts too soon, remains unhealthy, or loses work during stop. |
| [Compose include and genuine module boundaries](include-and-modularization.md) | a stack should be split into reusable subprojects with their own paths. |
| [Interpolation versus container environment](interpolation-and-environment.md) | an environment value is wrong, missing, or different between config and runtime. |
| [Merge, overrides, extension fields, and fragments](merge-overrides-and-fragments.md) | splitting development/production settings or removing an inherited port/mount. |
| [Compose networking and reachability](networks-and-service-discovery.md) | one service cannot reach another or a port is exposed unexpectedly. |
| [Profiles, optional services, and one-off jobs](profiles-and-jobs.md) | debug tools, migrations, test runners, or optional services are involved. |
| [Compose model, project identity, and command selection](project-model.md) | creating a stack, handling two checkouts, or explaining what a command will change. |
| [Resources, devices, replicas, and deployment semantics](resources-and-scaling.md) | limiting load, exposing accelerators, or scaling a service. |
| [Runtime secrets, configs, and trust boundaries](secrets-configs-and-trust.md) | distributing credentials or configuration to Compose services. |
| [Compose storage, ownership, and persistence](volumes-and-permissions.md) | choosing mounts, changing image versions, or debugging missing data/permission failures. |

## Example entrypoints

- [Modular lab: include, readiness, Watch, explicit override](../../examples/compose-lab/README.md)
- [Literal versus interpolated environment values](../../examples/environment/README.md)
- [Healthy dependency and one-shot completion](../../examples/lifecycle/README.md)

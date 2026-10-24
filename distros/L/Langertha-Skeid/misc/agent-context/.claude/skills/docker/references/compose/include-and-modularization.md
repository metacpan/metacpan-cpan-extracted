# Compose include and genuine module boundaries

> Read when: a stack should be split into reusable subprojects with their own paths.

`include` loads another Compose application model and imports its resources. Each included model resolves relative paths using its own project directory. This makes it suitable for a self-contained database, observability component, or shared service group. It is not the same mechanism as stacking override files.

```yaml
include:
  - path: ./modules/metrics/compose.yaml
services:
  app:
    image: "${APP_IMAGE:?Set APP_IMAGE}"
```

The included `metrics` model can use a local build context or config path without rewriting everything relative to the parent. Long syntax supports explicit `project_directory`, interpolation `env_file`, and a list of files merged to build that one included model.

## Collision and configuration rules

Imported service/network/volume names share the final model namespace. Include is not a namespacing operator. Resource-name collisions are not ordinary merge instructions; expect conflict diagnostics rather than designing around accidental override behavior. Use stable module-specific names or intentionally shared resources.

The included project can provide interpolation defaults, but the local project's environment can override them. Runtime service `env_file` is still a different concept. Remote or nested includes expand the trust surface: pin remote inputs when supported, review recursion and dependencies, and do not automatically fetch arbitrary include URLs from untrusted source material.

## Design a module interface

Document required interpolation variables, exported service names, shared networks, persistent volumes, secret/config requirements, minimum Compose capability, and update/rollback procedure. Avoid generic resource names like `db-data` across unrelated modules. State whether a parent may replace an included resource, and provide an explicit supported override path rather than relying on undocumented ordering.

## Acceptance test

Render the parent from a different working directory; verify module-local paths still resolve. Render two sibling inclusions to catch name collisions. Test missing required input. Check that a parent variable override changes only its documented contract. The included lab uses `include` for a small helper module so path behavior can be inspected without a large database stack.

## Primary sources

- [Compose include](https://docs.docker.com/reference/compose-file/include/)
- [Multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
- [Compose interpolation sources](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/)

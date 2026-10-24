# Versions, capabilities, and evidence

> Read when: choosing syntax, upgrading a host, or moving examples between machines.

## Capture the actual execution environment

Record client version, server version/API range, Compose version, Buildx version, selected context, builder driver, builder platforms, host OS, rootless status, and image-store backend. These are separate compatibility axes; “Docker is recent” is not evidence that all are recent.

```sh
docker version
docker compose version
docker buildx version
docker context show
docker info
docker buildx ls
```

`docker compose` is the maintained command spelling. Official documentation now describes both Compose v2 and v5; v5 retains the command and specification while adding a Go SDK. Do not confuse CLI major versions with old Compose file-format versions. The obsolete top-level `version:` does not enable new features.

## Feature gates, not a frozen latest-version claim

| Feature | Documented minimum / verification |
|---|---|
| Compose `include` | 2.20.0 |
| Compose Watch base support | 2.22.0; individual actions have later gates |
| `!override` merge tag | 2.24.4 |
| Optional service `env_file` via `required: false` | 2.24.0 |
| Service `env_file` `format: raw` | 2.30.0 |
| `sync+restart` Watch action | Check Develop reference; 2.23.0 |
| Watch `restart` / `sync+exec` | Check Develop reference; 2.32.0 |
| Engine API field | Check negotiated API plus field's version history |

These v2 introduction versions do not mean v5 is too old. Compare semantic version components, not strings. Validate the complete model using the installed CLI, including every intended profile/override combination.

On fresh Engine 29+ installations, the containerd image store changes data placement and capabilities. Upgraded hosts can retain classic storage. Detect the store rather than inferring it from the version alone.

## Reverification procedure

Before adopting an unfamiliar flag, inspect local `--help`, locate its versioned upstream contract, and run an isolated acceptance test. Record the exact versions, selected endpoint, command, observable effect, and rollback. Do not silently delete unsupported hardening fields to make validation pass. Documentation review date for this package: **2026-10-09**; this is not a live support guarantee.

## Primary sources

- [Compose history and versions](https://docs.docker.com/compose/intro/history/)
- [Compose include](https://docs.docker.com/reference/compose-file/include/)
- [Compose merge rules](https://docs.docker.com/reference/compose-file/merge/)
- [Setting container environment variables](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/)
- [Compose Develop Specification](https://docs.docker.com/reference/compose-file/develop/)
- [Daemon configuration and data directories](https://docs.docker.com/engine/daemon/)
- [Engine API compatibility](https://docs.docker.com/reference/api/engine/)

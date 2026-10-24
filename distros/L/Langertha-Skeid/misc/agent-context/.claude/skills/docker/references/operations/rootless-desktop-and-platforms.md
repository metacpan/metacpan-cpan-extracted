# Rootless, Docker Desktop, Windows, and Linux differences

> Read when: moving a stack between a Linux server and a developer workstation.

Record the daemon OS and container OS separately from the CLI OS. Docker Desktop commonly runs Linux containers in a VM even though the client is Windows or macOS. Native Windows containers have a different kernel, path, networking, and API capability surface. Shell snippets in this package use POSIX syntax unless explicitly labeled otherwise.

Rootless Docker runs the daemon and containers without host root, usually with a user-owned socket under the runtime directory. It is not equivalent to only setting `USER` in the image. Check subordinate UID/GID configuration, cgroup delegation, low-port handling, filesystem support, and the actual user service/context. Do not assume Linux rootful tuning applies unchanged.

## Filesystem and permissions

A Windows path, a WSL path, and a path in the Desktop VM are not interchangeable. Bind mount behavior and performance depend on the sharing mechanism. File ownership mapping, line endings, executable bits, file-watcher events, and case sensitivity can differ. Reproduce problems with a small fixture and keep source/code-storage placement explicit.

## Runtime features

Host networking, raw devices, GPU access, privileged behavior, and low-level firewall manipulation are platform-specific capabilities. Validate locally with the actual Engine and Desktop settings. A Compose file can be syntactically valid while a host lacks its required runtime feature.

## Handoff record

For a cross-platform bug report, include client OS, daemon OS/version, context type, rootless status, VM/WSL involvement, architecture, selected platform, image digest, mount source type, and the smallest failing operation. Redact usernames and private endpoints where necessary. Avoid “works on Docker” as a compatibility claim without specifying which Docker environment was tested.

## Primary sources

- [Rootless mode](https://docs.docker.com/engine/security/rootless/)
- [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/)
- [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [Daemon configuration and data directories](https://docs.docker.com/engine/daemon/)

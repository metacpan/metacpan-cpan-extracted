# Multi-platform images and output selection

> Read when: building for amd64/arm64 or debugging a missing or wrong-platform image.

A multi-platform release is an index/list pointing to platform-specific manifests. Distinguish the index digest from each child digest. Test the index through the registry, not only a locally loaded architecture-specific image.

Choose native workers, cross-compilation, or emulation deliberately. Emulation is useful for compatibility and bootstrapping but may distort build performance. Cross-compiling an executable does not prove that native extensions, libc, or runtime dependencies match the target. Test on native target hardware before making performance claims.

```sh
docker buildx inspect YOUR_BUILDER
# Creation of a new builder is a host mutation; do it only when approved.
docker buildx build --builder YOUR_BUILDER \
  --platform linux/amd64,linux/arm64 \
  --tag registry.example.com/team/app:COMMIT --push .
docker buildx imagetools inspect registry.example.com/team/app:COMMIT
```

Use automatic build/target platform arguments in a compiler stage when appropriate; redeclare needed `ARG`s in stage scope. Do not hardcode `--platform=linux/amd64` throughout the Dockerfile and then advertise the result as portable.

## Where did the result go?

A build can export to a registry, local archive, filesystem, or Engine image store. With a container-backed builder, successful execution does not imply the image appears in `docker images`. A classic Engine image store has different multi-platform and attestation support from the containerd store. Inspect the actual store and exporter before selecting `--load` or `--push`.

## Acceptance matrix

For every required platform: resolve the index, pull the intended child, start it, exercise the critical path, verify native modules, and check graceful shutdown. Confirm registry replication preserves all children and attached metadata. A single default-platform pull followed by retag/push is not an all-platform promotion strategy.

## Primary sources

- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [Build attestations](https://docs.docker.com/build/metadata/attestations/)

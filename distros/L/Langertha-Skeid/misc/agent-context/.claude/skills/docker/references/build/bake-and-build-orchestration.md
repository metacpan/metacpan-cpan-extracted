# Bake and build orchestration boundaries

> Read when: multiple images, targets, or CI parameter sets need a shared build definition.

Use Bake to describe related Buildx targets and reusable build settings. Use Compose to describe runtime service relationships. They can share image names and build inputs, but a successful Bake invocation says nothing about service readiness or persistent-data compatibility.

## Suggested repository pattern

Keep Dockerfiles with their services, one reviewed Bake file for release outputs, and explicit development/production Compose entry points. Make variables such as registry, release identifier, platform set, and cache references visible. Inspect the resolved Bake plan before execution:

```sh
docker buildx bake --print
# Review target contexts, Dockerfiles, secrets, tags, outputs, and platforms.
docker buildx bake release
```

The `release` target/group must exist in the project's own Bake file. Do not assume a target name from this reference.

## Avoid hidden coupling

Assign distinct release and cache references. Parameter changes must not accidentally redirect output to a developer's registry namespace. Keep secret values outside HCL/YAML; supply secret identifiers through the worker's credential mechanism. Review filesystem/network entitlements when using remote build definitions. Treat externally supplied Bake files as code capable of requesting privileged build behavior.

When deriving targets from Compose, inspect the generated model for every intended profile and override. Do not assume runtime secrets are automatically available at build time, or runtime environment variables automatically become build arguments.

## Validation and failure handling

First perform a configuration-only render, then build a single representative target, then the release group. Store the resulting per-platform digests and test report. If one target fails after another pushed successfully, record the partial publication and do not promote the incomplete set. A release manifest listing verified digests is a clearer handoff than “the pipeline was green.”

## Primary sources

- [Buildx Bake](https://docs.docker.com/build/bake/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Cache backends](https://docs.docker.com/build/cache/backends/)

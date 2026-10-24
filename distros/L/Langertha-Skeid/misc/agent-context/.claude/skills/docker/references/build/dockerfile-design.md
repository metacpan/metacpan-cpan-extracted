# Dockerfile design and runtime contracts

> Read when: writing or reviewing an image definition.

## Specify the contract before optimizing

Choose the executable, working directory, listening port, runtime UID/GID, writable paths, termination signal, startup configuration, and diagnostic interface. A small image that cannot load a required CA bundle or shared library is not a successful optimization.

Keep stable dependencies before frequently changed source. Copy lockfiles and manifests before dependency installation; copy source afterward. Use a multi-stage build when it removes a toolchain or cleanly separates test/package/runtime outputs. Multi-stage is not a requirement to add a redundant stage to a dependency-free application.

Use exec-form commands such as `CMD ["python", "app.py"]`. The literal word `exec` is not a magic JSON-array prefix. A shell wrapper should finish with `exec "$@"` when it merely prepares the environment. Exec form improves signal delivery but the application still needs to handle signals and reap children, or run with an init process.

`EXPOSE` documents a port; it does not publish it. A non-root `USER` does not make a writable bind mount harmless. Declare writable paths intentionally, then test with a read-only root filesystem.

## Layer and dependency discipline

Delete temporary package indexes in the same `RUN` that creates them. Otherwise earlier layers still contain them. Keep package installation atomic with the index update for package managers that require it. Choose slim versus Alpine versus distroless based on ABI, native dependencies, certificate needs, and debugging access—not the compressed-size number alone.

Build arguments are not secret storage. Avoid credentials in `ARG`, `ENV`, URLs, build logs, or copied package-manager files. Use the dedicated secrets reference. Pin base images by an approved digest for releases and keep an update process; pinning without patching only freezes vulnerabilities.

## Acceptance evidence

Build the final target, inspect configured user/command, run its health probe, stop it gracefully, and run the same image with required write restrictions and resource limits. Verify that runtime dependencies exist in the final stage, not merely in the builder. The included `examples/compose-lab/app/` demonstrates a dependency-free non-root service; it is a teaching fixture, not a production web server.

## Primary sources

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Building best practices](https://docs.docker.com/build/building/best-practices/)
- [Build secrets](https://docs.docker.com/build/building/secrets/)

# Cache design, invalidation, and CI ownership

> Read when: builds are slow, unexpectedly stale, or share caches across projects.

Separate four caches: build-step results, package-manager cache mounts, exported BuildKit cache, and registry pull-through cache. They save different work and have different trust/retention policies. A warm pull-through cache does not prevent recompilation; a package cache does not itself make a build-step result reusable.

## Diagnose before adding cache infrastructure

Compare two builds with unchanged input, then a source-only edit, then a lockfile edit. Identify the first unexpected invalidation. An ordinary `RUN` cache key does not become invalid merely because an upstream package repository changed. Secret **contents** do not automatically invalidate the step that consumes a secret. A controlled non-secret cache-bust input or targeted invalidation is needed when the result must change.

Use cache mounts for expensive reusable downloads, but do not depend on them being populated for correctness. Do not treat caches as final artifacts. Concurrent package-manager use may require a lock-sharing mode and separate platform-specific keys.

## CI pattern

```sh
docker buildx build \
  --cache-from type=registry,ref=registry.example.com/team/app-cache:main \
  --cache-to type=registry,ref=registry.example.com/team/app-cache:trusted-main,mode=max \
  --tag registry.example.com/team/app:COMMIT --push .
```

Substitute an immutable commit-derived release tag and your actual registry. Import/export references above intentionally differ: pick a promotion policy rather than allowing arbitrary jobs to overwrite the trusted cache. Untrusted pull requests must not write to trusted caches or receive push credentials. Branch-cache reads can be added after trust and storage budgets are clear.

`mode=max` retains intermediate build results and can save more work at the cost of size and exposure. Treat exported cache repositories as potentially sensitive. Driver and image-store support determine available backends; verify the chosen builder instead of assuming the default driver supports everything.

Measure cold/warm wall time, context bytes, cache transfer time, worker CPU/RAM, and cache growth. A remote cache can be slower than rebuilding a tiny project. Garbage-collect only caches whose owners and retention rules are known; do not combine performance tuning with unreviewed global prune commands.

## Primary sources

- [Cache invalidation](https://docs.docker.com/build/cache/invalidation/)
- [Cache optimization](https://docs.docker.com/build/cache/optimize/)
- [Cache backends](https://docs.docker.com/build/cache/backends/)

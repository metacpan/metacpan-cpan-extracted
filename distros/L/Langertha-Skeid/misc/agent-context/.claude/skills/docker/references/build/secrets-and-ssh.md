# Build secrets and SSH access

> Read when: a build downloads private dependencies or needs a private repository.

Use a build secret only for the instruction that needs it. Keep build-time credentials distinct from runtime secrets and registry login material.

```dockerfile
# syntax=docker/dockerfile:1
# Fragment: the base image must provide the actual package/download tool.
RUN --mount=type=secret,id=repo_token,required=true \
    your-package-tool --token-file /run/secrets/repo_token install
```

```sh
docker buildx build --secret id=repo_token,src=/secure/path/repo-token .
```

The fragment's package command is deliberately application-specific. Do not replace it with a real token literal. A mount prevents automatic persistence of the secret mount, not leakage by the invoked tool. Check logs, generated config, copied artifacts, cache exports, and provenance inputs for accidental disclosure. A malicious Dockerfile can read and transmit supplied credentials.

For private Git over SSH, forward a narrowly scoped agent through `--ssh`; validate host keys through a trusted known-hosts policy. Do not disable host checking or copy a private key into a layer. A remote Git context may need authentication before the Dockerfile runs; that uses context-fetch credentials rather than an arbitrary `RUN` mount.

## Rotation and correctness

When rotating a credential, revoke the old material and test retrieval using the new one. Do not rely on a previously cached successful dependency step as proof that the new credential works. Conversely, a changed secret value is not a reliable cache invalidator. Force a targeted rebuild when testing authentication, without printing the secret.

For CI, choose separate identities for base-image pulls, dependency downloads, output pushes, and cache writes where practical. Scope them to the repository and lifetime needed. Protect the worker and cache storage as well as the secret file; secret mounts are not a sandbox for hostile build definitions.

## Primary sources

- [Build secrets](https://docs.docker.com/build/building/secrets/)
- [Cache invalidation](https://docs.docker.com/build/cache/invalidation/)
- [Build attestations](https://docs.docker.com/build/metadata/attestations/)

# Release identity, SBOMs, provenance, and promotion

> Read when: publishing images or establishing a reproducible release process.

A release record should bind source revision, build definition, base-image digests, builder identity, output digest(s), platform set, tests, and attached metadata. Tags are convenient names; deploy an approved digest when identity matters. Digest integrity is not proof of publisher trust or vulnerability absence.

BuildKit can attach provenance and SBOM attestations. Check the builder/exporter/image-store combination: metadata that exists in a push result may not survive a local load/save or a third-party copy. Treat a successful build as the start of verification, not the final assurance claim.

```sh
docker buildx build --provenance=mode=min --sbom=true \
  --tag registry.example.com/team/app:COMMIT --push .
docker buildx imagetools inspect registry.example.com/team/app:COMMIT
```

This publishes an artifact and may launch/download an SBOM generator. Use an approved generator/toolchain in controlled environments. More detailed provenance can disclose build parameters; avoid secret-bearing arguments regardless of chosen mode.

## Promotion procedure

Build once, test the output digest, and promote that artifact instead of rebuilding “the same tag” for production. Copy the full index/children and required referrers using tooling whose behavior is tested. Verify digests and discoverability at the destination. Registry-side retention must protect signatures and attestations alongside the images they describe.

## Security decision, not a badge

Set policies for critical findings, exception owner/expiry, signing identity, freshness, and base refresh cadence. An SBOM is an inventory, not a security verdict. Provenance describes a build but does not automatically establish that the source or builder is trustworthy. Signature verification requires an independently trusted identity/key policy.

On a suspected leaked build credential, revoke it even when removed from the current Dockerfile: earlier images, intermediate caches, logs, and attestations may still contain the material. Continue with the `docker-registry` skill for retention, digest-preserving replication, and artifact discoverability.

## Primary sources

- [Build attestations](https://docs.docker.com/build/metadata/attestations/)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [Build secrets](https://docs.docker.com/build/building/secrets/)

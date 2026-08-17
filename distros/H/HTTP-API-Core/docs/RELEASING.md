# Releasing HTTP::API::Core

This document is the release checklist for maintainers. The goal is to make a release boring, reproducible, and easy to audit.

## Before changing the version

1. Start from an up-to-date `main` branch with no open release-blocking issues.
2. Confirm the GitHub Actions Perl matrix is green.
3. Run the full distribution test suite locally with `perl Makefile.PL && make test` when possible.
4. Review `Changes` and make sure every user-visible behavior change since the previous release is represented.
5. Confirm `MANIFEST` contains every file intended for the distribution.
6. Review the public compatibility documents under `docs/`, especially `COMPATIBILITY.md`.

For a major release such as 1.00, also confirm that every interface listed under the 1.0 criteria in `DESIGN.md` has explicit documentation and regression coverage.

## Prepare the release commit

1. Update `our $VERSION` in `lib/HTTP/API/Core.pm`.
2. Add the final version and release date to `Changes`.
3. Regenerate or inspect generated distribution metadata after `perl Makefile.PL`.
4. Build the distribution with `make dist`.
5. Inspect the resulting archive contents before upload.
6. Run the test suite against the release candidate archive when practical.

The release commit should contain only release-specific changes. Avoid mixing new features or behavioral changes into the version bump.

## Publish with GitHub Actions

After the release-preparation pull request is merged and the `main` CI run is green, use the `release` workflow from the GitHub Actions UI.

1. Choose **Run workflow** on the `release` workflow from `main`.
2. Enter the version without the `v` prefix, for example `1.00`.
3. The workflow verifies that the requested version matches `HTTP::API::Core::$VERSION` and that `Changes` contains the release entry.
4. It runs the test suite, builds `HTTP-API-Core-VERSION.tar.gz`, and verifies the archive contents.
5. It creates and pushes the `vVERSION` tag from the exact checked-out `main` revision.
6. It creates a GitHub Release for that tag and attaches the distribution archive.
7. The same archive is retained as a workflow artifact.

The workflow refuses to continue if the version does not match or if the tag already exists. This keeps the tag, GitHub Release, and distribution archive tied to one source revision.

## CPAN upload

Upload the distribution archive produced by the release workflow to CPAN using the maintainer's normal PAUSE workflow. CPAN credentials are intentionally not stored in this repository or required by the GitHub release workflow.

After uploading, verify that the CPAN/MetaCPAN release version and archive match the GitHub Release asset.

## After publishing

1. Verify the release appears correctly on MetaCPAN/CPAN.
2. Confirm the published archive reports the expected version and metadata.
3. Watch CI and downstream reports for packaging or compatibility regressions.
4. If a release-only packaging problem is found, prefer a small follow-up release rather than rewriting published history.

## 1.x compatibility reminder

After 1.00, documented public behavior is governed by `docs/COMPATIBILITY.md`. Additive changes are fine when they preserve existing contracts; breaking changes belong in a future major release unless a security or correctness issue requires an explicitly documented exception.

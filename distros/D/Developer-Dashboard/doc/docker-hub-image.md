# Docker Hub image workflow

`.github/workflows/dockerhub-image.yml` publishes the current `master` source
to Docker Hub on each push to `master`; `workflow_dispatch` also builds the
current `master` branch. The publishing job selects the GitHub Actions
environment named `release`; configure `DOCKER_HUB_USER` and
`DOCKER_HUB_TOKEN` as secrets in that environment. It publishes:

- `${DOCKER_HUB_USER}/developer-dashboard:<version>`
- `${DOCKER_HUB_USER}/developer-dashboard:latest`

The version comes from `dist.ini` and must be `X.XX`. Bump it before publishing
a materially different release if the previous version tag must remain a
rollback point. The workflow validates the Docker Hub namespace, pins its
third-party actions to commit SHAs, pins the Ubuntu base image by manifest
digest, and builds/pushes `linux/amd64` and `linux/arm64` manifests.

The image build context is the master checkout. Its Dockerfile runs the
repository `install.sh`, installs the Dist::Zilla toolchain, runs `dzil build`,
and then installs the generated versioned archive using `cpanm`. The archive
install runs its packaged tests and reinstalls even when the bootstrap step
already installed a CPAN distribution with the same version. This keeps the
image payload tied to the checked-out source rather than a potentially stale
MetaCPAN release. Local environments, Git history, and runtime state are
excluded from the Docker context. Versioned release tarballs are re-included
after the generated-artifact exclusions because the repository's local
`d2 docker.images.build` path copies the just-built archive into its image.
GitHub's clean checkout does not contain a stale tarball; the workflow builds
the archive from the checked-out source inside its Docker build.

Docker images use Linux kernels. The `linux/arm64` variant can run on Apple
Silicon through Docker Desktop's Linux VM; this workflow does not claim to
build a macOS-kernel container.

## Local verification

Run the workflow-contract test in the development container:

```bash
d2 docker compose exec dev prove -lv t/228-dockerhub-image-workflow.t
```

To validate the actual Dockerfile without publishing, build it through an
isolated Compose project with `d2 docker compose ... build`. A real Docker Hub
push is performed by GitHub Actions and requires the configured GitHub secrets.

# SimpiCI provider — [@Author::GETTY]

A [SimpiCI](https://github.com/Getty/simpici) **provider**: a tiny, pinned,
org-owned OCI image that generates a `dzil test` job for every Perl version this
bundle supports. It is the answer to "I have an `[@Author::GETTY]` distribution
and I want SimpiCI to test it" — without committing any `.cicd/` files.

## How it fits together

SimpiCI runs a provider image once, read-only over your checkout, with a private
writable directory (`$CICD_PROVIDER_OUT`). This image writes one job file per
supported Perl version there:

```
ghcr.io+getty+dzil-perl+5.22+test.sh
ghcr.io+getty+dzil-perl+5.24+test.sh
...
ghcr.io+getty+dzil-perl+5.44+test.sh
lib/dzil-test.sh      # shared helper the jobs source
```

In a SimpiCI filename `+` separates the image components and the last one is
the tag, so `ghcr.io+getty+dzil-perl+5.40+test.sh` runs in
`ghcr.io/getty/dzil-perl:5.40`, phase `test`. Without an explicit job name the
job is named after the image expression, `ghcr.io+getty+dzil-perl+5.40` —
unique per version.

Each generated job copies the read-only checkout into the writable output dir
(`dzil test` writes a build tree) and does a real `dzil test`, after
`dzil authordeps --missing` and `dzil listdeps --author --missing`. Since the
image already carries Dist::Zilla, the bundle and its author-test deps, those
install only what your dist adds on top — or a bundle released after the image
was built.

The provider receives **no registry credentials and no Docker socket** — it only
plans jobs.

## The `dzil-perl` images

`ghcr.io/getty/dzil-perl:<ver>` is the official `perl:<ver>` image (Debian, with
git and cpanm) plus Dist::Zilla, `[@Author::GETTY]` from CPAN with every plugin
it requires, and the develop-phase deps the bundle registers (`Test::Pod`). The
[`Containerfile`](dzil-perl/Containerfile) builds one per `PERL_VERSION`;
[`prime.sh`](dzil-perl/prime.sh) does the installing, through a throwaway
distribution so that `dzil listdeps --author` sees the same develop prereqs a
real dist does.

[`.github/workflows/dzil-perl-images.yml`](../.github/workflows/dzil-perl-images.yml)
publishes one tag per version in [`perl-versions`](perl-versions) on every push
to `main` that touches `dzil-perl/`, `perl-versions` or the workflow, weekly (so
the images follow new CPAN releases, including this bundle's own), and on
manual dispatch.

The images **must be public** on ghcr: a consuming repository pulls them with no
credentials of its own.

```sh
docker build --build-arg PERL_VERSION=5.40 -t ghcr.io/getty/dzil-perl:5.40 \
  -f dzil-perl/Containerfile dzil-perl
```

## Use it in a distribution

Add a single workflow — no `.cicd/` needed:

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
  pull_request:
concurrency:                                    # cancel a branch's superseded runs
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
jobs:
  simpici:
    permissions:
      contents: read
      packages: read
    uses: Getty/simpici/.github/workflows/simpici.yml@main
    with:
      provider: ghcr.io/getty/simpici-dzil-provider:main
```

Ship your own `.cicd/*.sh` to add jobs; the provider never clobbers a file you
already have. The merge goes by **filename**, so to replace the provider's job
for one version, ship a file of the same name:
`.cicd/ghcr.io+getty+dzil-perl+5.40+test.sh`. A `perl+5.40+test.sh` of your own
does not override anything: it is a different file with a different job name
(`perl+5.40`), so it runs *in addition to* the provider's
`ghcr.io+getty+dzil-perl+5.40` job. It can still use the helper —
`exec "$CICD_ROOT/lib/dzil-test.sh"` bootstraps Dist::Zilla itself on a plain
`perl:<ver>` image, just slower.

## System packages (`.simpici-apt`)

Some distributions need OS packages before their Perl dependencies will build —
a libgit2-backed dist, for instance, needs the C toolchain and headers so
`Alien::Libgit2` can compile libgit2 from source. List them, whitespace-separated,
in a `.simpici-apt` file at the repository root:

```
# .simpici-apt — apt packages installed before dzil test
cmake build-essential pkg-config
libssl-dev libssh2-1-dev zlib1g-dev libzstd-dev
```

Each generated job runs `apt-get install` for those packages — in its Debian-based
`dzil-perl:<ver>` container (same Debian release as `perl:<ver>`), before the
Perl deps are installed. The file is optional and `#` starts a comment; a
pure-perl dist ships none and no apt call is made.

A `[@Author::GETTY::Docker]` dist tests the same way as any other: the job exports
`DZIL_DOCKER_API_SKIP=1`, so `dzil test` never tries to reach a container engine
or build an image from inside the CI container.

## The version matrix

The supported versions live in [`perl-versions`](perl-versions) — the default,
whitespace-separated, and the list the `dzil-perl` images are built for. Two
things override it, most specific first:

- a **`.simpici-perl`** file at the repository root (one line or several,
  whitespace-separated, `#` starts a comment). Use it when a dist can't run the
  full range — most often because its `.simpici-apt` needs a Debian release that
  the oldest `perl:<ver>` images (Debian stretch/bullseye) no longer serve
  packages for, so the toolchain install 404s there:

  ```
  # .simpici-perl — only the perls whose images still have a live apt
  5.36 5.38 5.40 5.42 5.44
  ```

- the `SIMPICI_PROVIDER_PERL_VERSIONS` environment variable, for a one-run override.

Either one selects from the published images: a version that is not in
`perl-versions` has no `dzil-perl` tag, and its job fails to pull the image.

## Build

The provider image itself:

```sh
docker build -t ghcr.io/getty/simpici-dzil-provider:dev -f Containerfile .
```

Published automatically to `ghcr.io/getty/simpici-dzil-provider` by
[`.github/workflows/simpici-provider.yml`](../.github/workflows/simpici-provider.yml).

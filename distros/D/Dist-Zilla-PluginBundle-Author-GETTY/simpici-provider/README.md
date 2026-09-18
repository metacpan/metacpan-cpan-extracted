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
perl+5.22+test.sh
perl+5.24+test.sh
...
perl+5.44+test.sh
lib/dzil-test.sh      # shared helper the jobs source
```

SimpiCI merges those into the effective `.cicd` **without overwriting your own
files** — so if you ship your own `perl+5.40+test.sh`, yours wins. Each generated
job then runs in its `perl:<ver>` container and does a real `dzil test`
(bootstrapping Dist::Zilla, author deps and `listdeps --author`), copying the
read-only checkout into the writable output dir first because `dzil test` writes
a build tree.

The provider receives **no registry credentials and no Docker socket** — it only
plans jobs.

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

Ship your own `perl+<ver>+test.sh` (or any other `.cicd/*.sh`) to override or add
jobs; the provider never clobbers a file you already have.

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
`perl:<ver>` container, before bootstrapping Dist::Zilla. The file is optional and
`#` starts a comment; a pure-perl dist ships none and no apt call is made.

A `[@Author::GETTY::Docker]` dist tests the same way as any other: the job exports
`DZIL_DOCKER_API_SKIP=1`, so `dzil test` never tries to reach a container engine
or build an image from inside the `perl:<ver>` container.

## The version matrix

The supported versions live in [`perl-versions`](perl-versions) — the default,
whitespace-separated. Two things override it, most specific first:

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

## Build

```sh
docker build -t ghcr.io/getty/simpici-dzil-provider:dev -f Containerfile .
```

Published automatically to `ghcr.io/getty/simpici-dzil-provider` by
[`.github/workflows/simpici-provider.yml`](../.github/workflows/simpici-provider.yml).

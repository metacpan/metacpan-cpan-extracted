# release-binaries.yml skeleton

Replace `<name>` (binary and asset prefix), `<Module>` (the file holding `$VERSION`, as a
path below `lib/` without `.pm`, e.g. `Locale/Simple`; the same slot is `__Module__` in
the script templates) with the dist's own. The shape is the one a working dist shipped
(locale-simple is an example): an optional `tag` input (empty = probe run), a smoke job
on clean machines, and a tag-only release job.

```yaml
name: release-binaries

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag:
        description: Existing tag to build and attach assets to; empty = probe run (Actions artifacts only)
        required: false

# Least privilege: read by default; only the release job gets write.
permissions:
  contents: read

# Two runs for the same tag would race on gh release upload --clobber; they queue instead.
concurrency:
  group: release-binaries-${{ github.event.release.tag_name || inputs.tag || github.ref }}
  cancel-in-progress: false

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: linux
            arch: x86_64
            runner: ubuntu-latest
            image: perl:5.40-bullseye
          - os: linux
            arch: aarch64
            runner: ubuntu-24.04-arm
            image: perl:5.40-bullseye
          - os: macos
            arch: arm64
            runner: macos-14
    runs-on: ${{ matrix.runner }}
    timeout-minutes: 30
    # Linux builds run in the pinned bullseye image (glibc 2.31 sets the floor of the packed
    # XS modules, and the image decides which optional libs they link); macOS builds run on
    # the runner. The container has no gh; the release job runs on the plain runner.
    # The perl:5.40-bullseye image already carries git, unzip, gcc, g++, make, binutils and
    # cpanm, so there is no apt step (the build keeps working after bullseye moves to
    # archive.debian.org). Check a changed image first:
    #   docker run --rm <image> sh -c 'command -v git unzip gcc g++ make objdump cpanm'
    container: ${{ matrix.image || null }}
    # Values that reach a shell go through env, never inline ${{ }} in a run: body.
    env:
      TAG: ${{ github.event.release.tag_name || inputs.tag }}
      PLATFORM: ${{ matrix.os }}-${{ matrix.arch }}
    steps:
      - uses: actions/checkout@v5
        with:
          ref: ${{ env.TAG }}          # empty on a probe run: the dispatched ref
          persist-credentials: false
      - name: Fix safe.directory (Linux)
        if: matrix.os == 'linux'
        run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
      - name: Set up Perl 5.40 (macOS)
        if: matrix.os == 'macos'
        uses: shogo82148/actions-setup-perl@v1
        with:
          perl-version: '5.40'
      - name: Install Perl deps and PAR::Packer
        env:
          TAR_OPTIONS: "--warning=no-unknown-keyword"   # quiets GNU tar
        run: |
          cpanm --notest --installdeps .
          cpanm --notest PAR::Packer
      - name: Compute version and asset base name
        id: v
        run: |
          want=$(sed -n "s/^our \$VERSION = '\(.*\)';/\1/p" lib/<Module>.pm)
          # shellcheck disable=SC2016  # $VERSION is literal text in the message
          [ -n "$want" ] || { echo '::error::cannot read $VERSION from lib/<Module>.pm' >&2; exit 1; }
          if [ -n "$TAG" ]; then
            v="${TAG#v}"
            # A tag v0.200.0 may carry the dist version 0.200 that the binary prints.
            case "$v" in
              "$want"|"$want".*) ;;
              *) printf '::error::tag %s does not match the dist version %s\n' "$TAG" "$want" >&2; exit 1 ;;
            esac
          else
            v="probe-$(git rev-parse --short=7 HEAD)"
          fi
          echo "v=$v" >> "$GITHUB_OUTPUT"
          echo "base=<name>-$v-$PLATFORM" >> "$GITHUB_OUTPUT"
      - name: Build binary
        env:
          <NAME>_BIN_OUT: ${{ steps.v.outputs.base }}
        run: ./scripts/build-binary.sh
      - name: Verify binary
        env:
          BASE: ${{ steps.v.outputs.base }}
        run: ./scripts/verify-binary.sh "$BASE"
      - name: Check runtime libs
        env:
          BASE: ${{ steps.v.outputs.base }}
        run: |
          # A plain command: its exit code decides the step.
          ./scripts/check-binary-libs.sh "$BASE"
          for lib in $(./scripts/check-binary-libs.sh --list); do
            grep -qF "\`$lib\`" README.md \
              || { printf '::error::README.md does not list runtime lib %s\n' "$lib" >&2; exit 1; }
          done
      - name: Package
        env:
          BASE: ${{ steps.v.outputs.base }}
          V: ${{ steps.v.outputs.v }}
        run: |
          mkdir -p "pkg/$BASE"
          cp "$BASE" "pkg/$BASE/<name>"
          cp LICENSE "pkg/$BASE/LICENSE"
          libs=$(./scripts/check-binary-libs.sh --list)
          {
            printf '<name> %s (%s)\n\n' "$V" "$PLATFORM"
            printf 'Run it: ./<name> --help\nIt needs no Perl.\n\n'
            if [ -n "$libs" ]; then
              printf 'Runtime libraries required on the target: %s\n' "$libs"
              printf 'glibc 2.31 or newer.\n'
              printf 'Debian and Ubuntu have libcrypt.so.1; on RHEL, Fedora, Amazon Linux and Arch\n'
              printf 'install libxcrypt-compat.\n'
            else
              printf 'Runtime libraries required on the target: none beyond the system.\n'
            fi
            if [ "$RUNNER_OS" = macOS ]; then
              printf '\nAfter a browser download, clear the quarantine flag:\n'
              printf '  xattr -d com.apple.quarantine <name>\n'
            fi
            printf '\nhttps://github.com/%s\n' "$GITHUB_REPOSITORY"
          } > "pkg/$BASE/README"
          tar -C pkg -czf "$BASE.tar.gz" "$BASE"
      - name: Keep binary and tarball as workflow artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ${{ steps.v.outputs.base }}
          path: |
            ${{ steps.v.outputs.base }}
            ${{ steps.v.outputs.base }}.tar.gz
          if-no-files-found: error

  smoke:
    # Each artifact runs on a clean machine: no setup-perl, no build container, no Perl
    # modules from the build. Linux cells start the clean image with docker run on the
    # runner host (the image has no git, and checkout without git fetches the REST archive,
    # which honours export-ignore and drops scripts/ and the fixtures). macOS runs on the runner.
    needs: build
    strategy:
      fail-fast: false
      matrix:
        include:
          - {os: linux, arch: x86_64, runner: ubuntu-latest, image: 'almalinux:9', pkg: dnf}
          - {os: linux, arch: x86_64, runner: ubuntu-latest, image: 'ubuntu:22.04'}
          - {os: linux, arch: x86_64, runner: ubuntu-latest, image: 'debian:bullseye-slim'}
          - {os: linux, arch: aarch64, runner: ubuntu-24.04-arm, image: 'almalinux:9', pkg: dnf}
          - {os: macos, arch: arm64, runner: macos-14}
          - {os: macos, arch: arm64, runner: macos-15}
    runs-on: ${{ matrix.runner }}
    timeout-minutes: 30
    env:
      TAG: ${{ github.event.release.tag_name || inputs.tag }}
      PLATFORM: ${{ matrix.os }}-${{ matrix.arch }}
    steps:
      - name: Assert no build Perl on the machine (macOS)
        if: matrix.os == 'macos'
        run: |
          if [ -e /Users/runner/hostedtoolcache/perl ]; then
            echo '::error::/Users/runner/hostedtoolcache/perl exists; the smoke test would prove nothing' >&2
            exit 1
          fi
      - uses: actions/checkout@v5
        with:
          ref: ${{ env.TAG }}          # empty on a probe run: the dispatched ref
          persist-credentials: false
      - uses: actions/download-artifact@v4
        with:
          pattern: <name>-*-${{ env.PLATFORM }}
          merge-multiple: true
          path: dl
      - name: Smoke-test the binary (macOS)
        if: matrix.os == 'macos'
        run: ./scripts/smoke-binary.sh dl/<name>-*-"$PLATFORM" dl/<name>-*-"$PLATFORM".tar.gz
      - name: Smoke-test the binary in a clean image (Linux)
        if: matrix.os == 'linux'
        env:
          IMAGE: ${{ matrix.image }}
          PKG: ${{ matrix.pkg }}
        run: |
          docker run --rm -i -v "$PWD:/w" -w /w -e PLATFORM -e PKG "$IMAGE" sh -s <<'EOF'
          set -eu
          if [ "$PKG" = dnf ]; then
            # A mirror answers badly now and then; three tries keep one bad response from failing the run.
            ok=
            for _try in 1 2 3; do
              if dnf install -y libxcrypt-compat tar gzip diffutils; then ok=1; break; fi
              sleep 10
            done
            [ -n "$ok" ] || { echo '::error::dnf install failed three times' >&2; exit 1; }
          fi
          # The build image compiles /usr/local/lib/perl5 into the binary's @INC.
          if [ -e /usr/local/lib/perl5 ]; then
            echo '::error::/usr/local/lib/perl5 exists; the smoke test would prove nothing' >&2
            exit 1
          fi
          ./scripts/smoke-binary.sh dl/<name>-*-"$PLATFORM" dl/<name>-*-"$PLATFORM".tar.gz
          EOF

  release:
    # Tag mode only: one checksums file over every asset, then all assets onto the release.
    needs: [build, smoke]
    if: github.event.release.tag_name != '' || inputs.tag != ''
    runs-on: ubuntu-latest
    timeout-minutes: 15
    # The only job that writes: it uploads the assets to the release.
    permissions:
      contents: write
    env:
      TAG: ${{ github.event.release.tag_name || inputs.tag }}
      GH_TOKEN: ${{ github.token }}
    steps:
      - uses: actions/download-artifact@v4
        with:
          pattern: <name>-*
          merge-multiple: true
          path: dl
      - name: Write checksums and upload every asset
        run: |
          v="${TAG#v}"
          out="<name>-$v-checksums.txt"
          ( cd dl && sha256sum <name>-* ) > "$out"
          cat "$out"
          gh release upload "$TAG" dl/<name>-* "$out" \
            --clobber --repo "$GITHUB_REPOSITORY"
```

The `dl/<name>-*` glob matches binaries and tarballs, never the checksums file or the CPAN
dist tarball, so a re-run does not hash its own output.

## What the dist README tells users

````markdown
### Binary (no Perl needed)

Each GitHub release carries `<name>` as one standalone binary per platform
(`<name>-<V>-linux-x86_64`, `-linux-aarch64`, `-macos-arm64`), also as `.tar.gz`
(a directory `<name>-<V>-<platform>/` with `<name>`, `LICENSE` and `README`), and
`<name>-<V>-checksums.txt` holds the `sha256sum` line of every asset. The bare binary
arrives without the executable bit, as HTTP downloads carry no file mode;
`install -m 755` (or `chmod +x`) sets it, and the `.tar.gz` keeps it. The `mkdir -p`
before `install` serves a fresh account, and BSD `install` on macOS has no `-D`.

```bash
V=1.2.3 P=linux-x86_64
base=https://github.com/<owner>/<repo>/releases/download/v$V
curl -fLO "$base/<name>-$V-$P"
curl -fLO "$base/<name>-$V-checksums.txt"
grep " <name>-$V-$P\$" "<name>-$V-checksums.txt" | sha256sum -c
mkdir -p ~/.local/bin
install -m 755 "<name>-$V-$P" ~/.local/bin/<name>
<name> --version
```

On macOS, `shasum -a 256 -c` takes the place of `sha256sum -c`.

Linux needs glibc 2.31 or newer and `libcrypt.so.1` (`libcrypt`). Debian and Ubuntu
carry it; on RHEL, Rocky, Alma, Fedora, Amazon Linux and Arch install
`libxcrypt-compat`. The macOS binary runs on Apple Silicon and needs nothing installed.
It is unsigned: after a browser download clear the quarantine flag with
`xattr -d com.apple.quarantine <name>` (a `curl` download sets no flag).
````

The backticked `libcrypt` is what the CI grep for `--list` finds. Name every lib `--list`
prints the same way.

## Extras

- Alien dependency: install the build-tool Alien first, then the share-built one.
  ```bash
  cpanm --notest Alien::cmake3
  ALIEN_INSTALL_TYPE=share cpanm --notest Alien::Foo
  ```
- Recommends that the binary needs although `--installdeps` skips them:
  `cpanm --notest IO::Async::SSL Mozilla::CA`, and make `build-binary.sh` refuse to
  build without them.
- Example config in the tarball: `cp share/example-config.yaml "pkg/$BASE/<name>.example.yaml"`.
- `.gitattributes` `export-ignore` for `scripts/` and `t/` shapes only `git archive`
  (source zips, Packagist); the workflow checks out with git and is unaffected.

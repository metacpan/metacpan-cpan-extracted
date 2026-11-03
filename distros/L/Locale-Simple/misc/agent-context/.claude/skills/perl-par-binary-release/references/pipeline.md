# Pipeline detail

The per-script rules behind `SKILL.md`: what each script checks and why. Templates are in
[scripts.md](scripts.md) and [workflow.md](workflow.md).

## build-binary.sh and loaded-modules.pl

`set -euo pipefail`, run from the checkout root, output path from `<NAME>_BIN_OUT`.

```bash
PAR_VERBATIM=1 pp -o "$OUT" -I lib "${mods[@]}" -M 'Dist::**' bin/<name>
```

- **`PAR_VERBATIM=1`** switches off pp's POD-stripping filter, which corrupts files with
  POD interleaved with code until a module "did not return a true value".
- **`-I lib`** puts the checkout's `lib/` first on `@INC`, so the dist resolves although
  it is not installed in the CI container.
- **One computed module set for build and verify.** `scripts/loaded-modules.pl` loads the
  dist's namespace for real, runs every command path (help, version, each subcommand, the
  error paths) and prints the `%INC` entries that come from their own file. Build turns
  each line into `-M`; verify requires each inside the binary. One source, so the two
  cannot drift. pp's scanner reads source and misses whatever loads by name
  (`Module::Runtime`, `require $class`, backend choosers like `Locale::TextDomain`,
  `Module::Pluggable`, Moose meta roles, JSON/loop backends, `YAML::PP` schemas); the
  script lists such backends explicitly. The build fails when the set is suspiciously
  small.
- A `-M 'Pkg::**'` glob covers a namespace whose members load on some path only. It
  searches all of `@INC`, so name modules one by one (from `find lib` or the installed
  dist's `.packlist`) when sibling dists share the namespace or an older release left
  stale files in it.
- **Guard optional modules**: `-M` on a module that is not installed aborts pp, so add
  it with `perl -Ilib -M"$m" -e1 && opts+=(-M "$m")`.
- **Share directories via `-a "<src>;lib/auto/share/dist/<Dist-Name>"`**, where an
  installed dist's share lands below an `@INC` dir, so `File::ShareDir::dist_dir` finds
  it. pp packs no share tree by itself and exits 0 for an `-a` path that is not there.
  Pack the dist's own `share/` and each dependency's share tree that is read.
- **`-X <Module>`** leaves out an optional module that links a lib the target may lack
  (`Term::ReadLine::Gnu`, Brotli codecs, `Net::LibIDN`); the code falls back.
- **`-X` drops one file.** `pp -X Name` removes exactly `Name.pm`, has no wildcard, and the
  scanner still follows `require Name` into the module's own dependencies. To leave out a
  module that only some runners have installed (an output format such as `YAML`, present
  on the macOS runner), add one `-X` per module of its family found in `@INC` on the
  build host. `loaded-modules.pl` omits the family from the set, and verify rejects any
  file of the family inside the archive, so every binary has the same features on every
  platform. Walking the `<Path>/` directory leaves out the whole namespace, sibling dists
  included (for `YAML`: `YAML::PP`, `YAML::XS`, `YAML::Tiny`); a module the CLI needs from
  that namespace stays in the loaded set, so verify fails the build and the walk is
  narrowed then. The CLI then reports the missing module for that option, the same everywhere.
- Guards at the top refuse to build when a precondition is missing: Alien not a `share`
  build, a runtime dependency not installed, not at the checkout root.
- Each `-M`/`-a`/`-X` line carries a comment naming the runtime failure it prevents.

## verify-binary.sh

Takes the binary path, runs from a throwaway cwd, treats the binary as a user's machine
would, and runs where it was built.

- **Fresh `PAR_GLOBAL_TEMP="$(mktemp -d)"`**, so the first start (extraction) is the one
  under test; then a second start on the same cache.
- **A wiped environment** (`env -i PATH=... HOME="$work/home" PAR_GLOBAL_TEMP=...`): no
  `PERL5LIB` to lean on, no credentials, no network; where the CLI talks HTTP, a fake
  upstream on 127.0.0.1.
- **Compare with the source tree.** `perl -Ilib bin/<name> ...` is the reference: same
  stdout and exit code on success and error paths, and a reference that printed nothing
  fails the case. Compare `--version` with `$VERSION`, shipped files byte for byte
  (`cmp`), and every module of the computed set inside the unzipped archive. Verify
  outside the build's `@INC`: the host's modules mask a missing one, so the check reads
  the archive's `lib/`, never the host.
- **Reach every path that loads by name**: `--help` per subcommand, one real round trip
  per backend. Bound each run with `timeout` (macOS: a `perl -e 'alarm shift; exec @ARGV'`
  fallback), since a missing module can hang.
- `fail()` prints the cause; one `OK` line per stage and a final `verify: OK`.

## check-binary-libs.sh

A packed binary is portable when everything in it needs only the libs the README names.

- Unpack the binary (a zip behind the ELF head; `unzip` exit 1 is a warning, 2 and up a
  failure) and run `ldd` (Darwin: `otool -L`, with the system dylibs as `BASE_LIBS`) on
  the loader and every shared object inside. Compare names against `RUNTIME_LIBS` (what
  a target installs) and `BASE_LIBS` (`libc libm libpthread libdl librt libgcc_s
  ld-linux-.* linux-vdso libperl`); `libfoo.so.0 => not found` counts like a resolved one.
- **Runtime libs the loader needs come from the system.** The `pp` loader executable
  links libperl, which needs `libcrypt.so.1` before PAR extracts anything, so `pp -l`
  cannot pack it. List such libs in `RUNTIME_LIBS`, the one place the set lives
  (`check-binary-libs.sh --list`), name them in the README with the package that carries
  them (RHEL, Rocky, Alma, Fedora, Amazon Linux, Arch: `libxcrypt-compat`), and let CI
  grep `README.md` for every listed lib in backticks.
- A violation prints `::error::undocumented runtime lib <lib>, needed by: <objects>` and
  exits 1. The remedy is a base image that does not link it, an `-X`, or an entry in
  `RUNTIME_LIBS` and the README.
- The glibc check takes the highest `GLIBC_x.y` among the objects' undefined symbols
  (`objdump -T`) and compares it with `GLIBC_MAX`.

## smoke-binary.sh and the smoke job

Smoke what users download, on machines that never built it.

- Cells: `almalinux:9`, `ubuntu:22.04`, `debian:bullseye-slim` (x86_64), `almalinux:9`
  (aarch64), `macos-14`, `macos-15`. No setup-perl, no build container; the script runs
  under `env -i` and the cell asserts the build Perl is absent (`/usr/local/lib/perl5`
  on Linux, the hosted-toolcache perl on macOS).
- **Linux cells start the clean image with `docker run`** on the runner host, checkout
  and artifacts mounted. A clean image has no git, and `actions/checkout` without git
  fetches the REST archive, which honours `export-ignore`, so scripts and test fixtures
  go missing. The `dnf` cells install the runtime lib with a three-try retry loop.
- With the tarball the script unpacks it: one directory named like the tarball, holding
  the binary (executable as extracted, `cmp`-identical to the bare asset), `LICENSE` and
  `README`; the checks then run against the extracted binary.
- **Every subcommand gets a smoke case**: it runs on a fixture and its output is compared
  byte for byte with a checked-in expectation, plus one error path. A `t/` test (the keeper
  test, end of [scripts.md](scripts.md)) runs the same subcommand through the Perl code
  against the same file, so the expectation equals what the Perl code writes.

## Packaging, checksums, users

- Per platform: the raw binary and `<base>.tar.gz` holding `<base>/<name>`, `LICENSE`
  and a README (version, platform, runtime libs, glibc floor, quarantine hint on macOS,
  repository URL); `<base>` is `<name>-<version>-<os>-<arch>`. Build jobs upload both as
  Actions artifacts in every mode.
- The `release` job (`needs: [build, smoke]`) downloads all artifacts and writes one
  `<name>-<version>-checksums.txt` (`sha256sum` over every asset), then runs
  `gh release upload "$TAG" dl/<name>-* "$out" --clobber`. It runs on the plain runner,
  where `gh` exists; `GH_TOKEN: ${{ github.token }}` goes in its `env:`.
- `release: published` fires for a release made with a personal token; a release created
  by a workflow's `GITHUB_TOKEN` starts no workflow. Create the release the way the
  dist's release tool does (`dzil release`), or dispatch the workflow with the tag.
- **The dist README tells users** (text in [workflow.md](workflow.md)): the bare asset
  arrives without the executable bit (HTTP downloads carry no mode, `upload-artifact`
  drops it too), so `mkdir -p ~/.local/bin` and `install -m 755` (or `chmod +x`);
  `mkdir -p` because BSD `install` on macOS has no `-D`, and a fresh account has no
  `~/.local/bin`. The checksum check `grep " <asset>\$" <checksums> | sha256sum -c`
  (macOS: `shasum -a 256 -c`) works without `--ignore-missing`; the macOS binary is
  unsigned, so after a browser download `xattr -d com.apple.quarantine <name>` (a `curl`
  download sets no flag).

# Implementation Notes

## Architecture Overview

cpancover uses a multi-layer Docker architecture:

```text
Host System
└── Controller Container (orchestrates coverage runs)
    └── Worker Containers (one per module, Docker-in-Docker)
```

### Docker Image Layers

1. **perl-5.42.0** - Ubuntu 24.04 with Perl (566MB after multi-stage build)
2. **devel-cover-base** - Build tools, Docker CLI, CPAN dependencies (925MB)
3. **devel-cover-dc** - Devel::Cover source (git or local variants) (926MB)
4. **cpancover** - Final image with Devel::Cover installed (926MB)

### Key Files

- `utils/dc` - Main orchestration script with recipes
- `bin/cpancover` - CLI entry point
- `lib/Devel/Cover/Collection.pm` - Core coverage collection logic
- `docker/BUILD` - Docker image build script (generates perl Dockerfiles)
- `docker/*/Dockerfile` - Image definitions
- `utils/Devel/Cover/BuildUtils.pm` - `nice_cpus` and build utilities

## Log Link Resolution

### How `.log_ref` files are created

`recipe_cpancover-docker-module` (utils/dc:488-529):
1. Builds module in Docker container
2. Saves container logs to `$staging/$log_name.out` (line 506)
3. Copies coverage result directories from container (line 509-519)
4. For each result directory, writes `.log_ref` containing
   `$log_name.out.gz` (line 517)

The `$log_name` is `$name` before Docker name sanitisation (line 494),
which is `$module-$timestamp` (generated in Collection.pm:497).

**Key insight**: When module X is built, its dependencies Y, Z also
produce coverage directories. ALL of them get `.log_ref` pointing to
X's log — not their own. So `.log_ref` for a dependency module points
to the parent module's build log.

### Resolution priority (Collection.pm `resolve_log_links`)

1. **`.out.gz` filename match** — regex matches top-level log files
   to module directory names. Works for both old pre-Docker logs
   (~146k files in staging_dev) and new Docker builds. Since `@mods`
   is sorted, the last (most recent) timestamp wins for a given
   module.

2. **`.log_ref` fallback** — for dependency modules that have no
   matching `.out.gz`. The log is for the parent module's build,
   but is better than nothing.

3. **No link** — template conditional (`[% IF vals.$m.log %]`)
   suppresses the pilcrow for modules with no log at all.

### The regex

```perl
my $re  = qr/^\w-\w\w-\w+-(.*)/;        # CPAN author path prefix
my $ext = qr/\.(zip|tgz|tar\.(gz|bz2|xz))/;  # distribution extension
my $ts  = qr/--\d{10,11}\.\d{6}\.out\.gz$/;   # timestamp + .out.gz
```

Example: `T-TI-TINITA-YAML-PP-v0.39.0.tar.gz--1772444171.049291.out.gz`
→ captures `YAML-PP-v0.39.0` which matches the directory name.

## Multi-Stage Perl Build

### Problem

Original perl Dockerfile used `build-essential` (~372MB) and kept build tools
in the final image.

### Solution

Two-stage build in `docker/BUILD`:

```bash
# Stage 1: Build environment
FROM ubuntu:24.04 AS builder
RUN apt-get install gcc libc6-dev libssl-dev make wget zlib1g-dev
RUN wget perl-X.Y.Z.tar.gz && ./Configure -des -Doptimize='-O2' && make install
RUN find /usr/local -type f -executable -exec strip --strip-unneeded {} \;

# Stage 2: Runtime environment
FROM ubuntu:24.04
RUN apt-get install gcc libc6-dev make  # Minimal tools for CPAN
COPY --from=builder /usr/local /usr/local
```

**Result**: perl image 672MB → 566MB (16% reduction)

### Important Notes

- Perl Dockerfiles are **auto-generated** by `docker/BUILD`
- Comment at top warns not to edit directly
- CPAN modules need gcc/make for XS compilation, so minimal build tools kept

## TTY Handling Fix

### Problem

`cpancover_controller_command()` used `docker run -it` which requires a TTY.
When running non-interactively, this fails.

### Solution

```bash
local tty_flag=""
[[ -t 0 ]] && tty_flag="-t"
"$docker" run -i ${tty_flag:+"$tty_flag"} ...
```

**Key**: `${tty_flag:+"$tty_flag"}` expands to nothing when empty (no outer
quotes), avoiding empty string argument to docker.

## Environment Variable Forwarding

### Problem

Environment variables like `CPANCOVER_TEST_REGEX` and `DEVEL_COVER_CPUS`
weren't forwarded into the controller container, so they had no effect on
the containerised cpancover run.

### Solution

Generic forwarding of all `CPANCOVER_*` and `DEVEL_COVER_*` variables in
`cpancover_controller_command()` (`utils/dc:350-353`):

```bash
local env_flags=()
while IFS='=' read -r var value; do
  env_flags+=(--env "$var=$value")
done < <(env | grep -E '^(CPANCOVER_|DEVEL_COVER_)' || true)
```

### Array Quoting Bug

The `env_flags` array was originally expanded with outer quotes:
```bash
"${env_flags[@]:+${env_flags[@]}}"
```

This collapsed the array into a single string, so docker received
`"--env CPANCOVER_TEST_REGEX=Dancer2"` as one argument instead of two.

Fixed to inner quotes (matching the `tty_flag` pattern):
```bash
${env_flags[@]:+"${env_flags[@]}"}
```

### Supported Variables

- `CPANCOVER_TEST_REGEX` - Filter `--latest` module list with regex
- `CPANCOVER_TEST_MODULES` - Override module list entirely (highest priority)
- `DEVEL_COVER_CPUS` - Override `nice_cpus` CPU count
- `DEVEL_COVER_TIMEOUT` - Per-module container timeout (default 1800s)

## Container Timeout Fix

### Problem

Worker containers (one per CPAN module) could hang indefinitely. Three
overlapping failures:

1. **Perl `alarm` broken by safe signals**: The `alarm`/`SIGALRM` timeouts
   in `_sys` (`Collection.pm:96`) and `cover_modules` (`Collection.pm:501`)
   are ineffective. Perl 5.8+ safe signals use `SA_RESTART`, so C-level
   blocking calls (`read()` in `_sys`, `waitpid()` in `cover_modules`)
   are restarted after signal delivery. The Perl-level `die` handler is
   never dispatched.

2. **`docker run -d` escapes process kill**: Even if the alarm worked,
   `kill "-KILL", $pgrp` only kills the `dc` shell script and `docker wait`.
   The detached container (started with `docker run -d`) runs independently
   on the Docker daemon.

3. **`--rm=false` prevents cleanup**: Containers persist after the process
   inside them exits, requiring explicit `docker rm`.

### Solution

Shell-level `timeout` command in `recipe_cpancover-docker-module`
(`utils/dc:392`):

```bash
local module_timeout="${DEVEL_COVER_TIMEOUT:-1800}"
if timeout "$module_timeout" $docker wait "$name" >/dev/null 2>&1; then
  # Success: copy results
  ...
else
  pi "module timed out after ${module_timeout}s, killing container: $module"
  $docker kill "$name" >/dev/null 2>&1 || true
fi
$docker rm "$name" >/dev/null 2>&1 || true
```

### Future Improvement

A proper Perl-level fix would use `POSIX::sigaction` with `SA_RESTART`
disabled, or `Sys::SigAction`. However, the shell-level fix is more
robust for the Docker use case since it also handles the "detached
container escapes process kill" problem.

## Test Recipes

### Usage

```bash
dc -e dev cpancover-test                 # Direct execution
dc -e dev cpancover-controller-test      # Via controller

# Filter to specific modules (realistic test)
CPANCOVER_TEST_REGEX='Dancer2' dc -e dev cpancover-controller-run-once

# Custom module
CPANCOVER_TEST_MODULES="A/AU/AUTHOR/Mod.tar.gz" dc -e dev cpancover-controller-test

# With custom timeout and CPU limit
DEVEL_COVER_TIMEOUT=120 DEVEL_COVER_CPUS=4 CPANCOVER_TEST_REGEX='Dancer2-T' \
  dc -e dev cpancover-controller-run-once
```

## shfmt Compatibility

### Patterns Used

1. **Optional scalar**: `${var:+"$var"}` without outer quotes
2. **Optional array**: `${arr[@]:+"${arr[@]}"}` without outer quotes
   - NOT `"${arr[@]:+${arr[@]}}"` (outer quotes collapse array)
3. **Quoting commands**: `"$docker"`, `"$build"`
4. **Mount options**: `--mount "type=bind,source=$var,target=$target"`

## Important: Rebuild After Code Changes

The `dc` script and Perl modules are baked into Docker images at build
time. There are NO source mounts in `cpancover_controller_command` —
only the Docker socket and results directory are mounted. After any
code change to `utils/dc`, `bin/cpancover`, or `lib/Devel/Cover/*.pm`,
you must run `dc -e dev docker-build` to pick up the changes inside
containers.

## Compression Architecture

### Functions

- `cpancover_compress_dir(dir, do_sidecars, prefix, ...excludes)`
  — Single directory: cleanup, compress, optionally create sidecars
- `cpancover_compress_dirs(only_new)` — Iterates all directories,
  parallelises with `wait -n`, max jobs = `nice_cpus`
- `cpancover_compress()` — Full compress of all directories
- `cpancover_compress_new()` — Only directories without
  `virtual_unzipped` (used after `generate_html`)

### Sidecar placeholders (Caddy precompressed gzip)

Caddy's `precompressed gzip` directive looks for `foo.gz` alongside
`foo`. For each `.gz` file, an empty `virtual_unzipped` marker is
created and hardlinked as the uncompressed filename. This lets Caddy
find the precompressed file without storing duplicate content.

**Gotcha**: sidecars must NOT be created at the top level, as files
like `index.html` must be served with real content (not empty
placeholders) for clients that don't accept gzip.

### compress_old_versions (Collection.pm)

Archives old module versions as `.tar.xz`:
1. Uncompress directory with `gzip -df` (needs `-f` for sidecars)
2. Archive with `tar | xz` (needs `xz-utils` in Docker image)
3. Remove directory

Version comparison uses `version->parse` which overflows on large
version numbers (e.g. `20231006.001`). Suppressed with
`no warnings "overflow"`.

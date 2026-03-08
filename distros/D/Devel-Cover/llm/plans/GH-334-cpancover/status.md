# GH-334: Get cpancover running entirely within Docker

## Objective

Make cpancover fully containerised so it's trivial to set up on a new
server.

## Current Phase

**Testing and bug-fixing** — log link resolution reworked, template
conditional added, ready for testing.

## Completed (previous sessions)

### Compression overhaul (`4fe3d4df`)

- Replaced `gzip` with `pigz` for multi-core compression
- Excluded `.xz` files from compression
- Cleaned up stale DB files (cover.[0-9]*, digests), lock files,
  runs/, structure/ per directory
- Created Caddy sidecar placeholders only in subdirectories
- Protected top-level files (about.html, index.html, collection.css,
  cpancover.json) from compression
- Skipped `__failed__` and `dist` subdirectories
- Parallelised subdirectory compression (`wait -n`, configurable
  via `CPANCOVER_COMPRESS_JOBS`, defaults to `nice_cpus`)
- Added `cpancover-compress-new` recipe for incremental compression
  (only processes directories without `virtual_unzipped`)

### Generate HTML workflow (`e176edcd`)

- Changed `cpancover_generate_html` to use `cpancover_compress_new`
  instead of full `cpancover_compress`

### Zsh completion (`cb0976cd`)

- Switched from compctl/reply to compdef/_describe
- Fixed shellcheck warnings, corrected shebang to `#!/bin/bash`

### Default test module update (`0a3a0a6c`)

- Updated to latest Perl-Critic-PJCJ version

### tar.xz regex fix (`b7b613dc`)

- Added `tar.xz` to distribution regexes in Collection.pm (log file
  matching and module name extraction)

### Version overflow warning (`c159f11c`)

- Suppressed "Integer overflow in version" warning in
  `compress_old_versions`

### Docker module build logs (`a8fe991c`)

- Save Docker module build logs

## Completed (this session)

### Log link resolution rework

Reworked how `generate_html` resolves log links for modules:

1. **Extracted `resolve_log_links` method** from `generate_html`
   (Collection.pm:307-332) to reduce perlcritic complexity score.

2. **Two-pass priority system**:
   - Pass 1: Match top-level `.out.gz` filenames to module names
     via regex. Covers both old pre-Docker logs and new Docker
     build logs (since `recipe_cpancover-docker-module` writes
     `$staging/$log_name.out` at line 506 of `utils/dc`).
   - Pass 2 (fallback): Read `.log_ref` files for modules that
     had no `.out.gz` match. These are dependency modules — when
     module X is built via Docker, its dependencies Y, Z get
     coverage directories with `.log_ref` pointing to X's log.

   Priority: module's own `.out.gz` > `.log_ref` (dependency log)

3. **Conditional pilcrow link** in template (line 713): only render
   the `¶` log link when `vals.$m.log` is set, avoiding broken
   links for modules with no log file.

### Problem that was fixed

The previous `.log_ref`-only approach broke log links for ~62,000
old pre-Docker modules. Only 11 modules (from recent Docker test
runs) had `.log_ref` files, and those all pointed to the same
Perl-Critic-PJCJ build log (since all were dependencies of that
single test module). The old code path (commit `f672c986`) had
scanned the directory listing for `.out.gz` files; this was lost
when `.log_ref` was introduced.

## Uncommitted Changes

Two files modified:

1. `lib/Devel/Cover/Collection.pm`:
   - Extracted `resolve_log_links($d, $mods, $vars)` method
   - Two-pass log resolution (`.out.gz` match, then `.log_ref`)
   - Conditional `¶` link in HTML template
2. `utils/dc`:
   - `-f` flag for `gzip -d` in `cpancover-uncompress-dir`
   - Delete stale `dist/*.gz` before compression

## Branch Status

- Branch: `GH-334-cpancover`
- 35 commits ahead of `main` (plus uncommitted fixes above)
- Partially pushed to remote

## Test Results (from previous sessions)

- `dc -e dev docker-build` — succeeds
- `dc -e dev cpancover-controller-test` — succeeds
- `dc -e dev cpancover-serve` — serves correctly
- `dc cpancover-compress` — idempotent on second run
- Compression parallelisation working

## Known Issues

1. `cover --test` fails for List-SomeUtils, List-SomeUtils-XS,
   Readonly (XS module test failures under coverage — pre-existing)
2. Perl safe signals break alarm-based timeouts (worked around with
   shell `timeout`)

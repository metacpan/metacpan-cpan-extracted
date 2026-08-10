---
name: libgit2-core
description: "Architecture + binding patterns for the Git::Libgit2 distribution — what FFI::Platypus surface looks like, opaque-handle ownership, Error wrapper, the test isolation contract."
metadata:
  type: project
---

# Git::Libgit2 — core architecture

This skill is loaded into every libgit2-* agent's context before its first turn.
Do not duplicate its content in the agent body.

## What this distribution is

Low-level FFI::Platypus bindings to libgit2, via Alien::Libgit2. 1:1 surface of
libgit2's C API exposed as Perl subs. **No Moo, no objects, no
error-to-exception translation** — that lives one layer up in `Git::Native`.

`Git::Libgit2::FFI` is a singleton — one FFI per process. The package's own
`ffi()` method returns that singleton; do not create a second one.

## Module map

| Module | Owns |
|---|---|
| `Git::Libgit2` | top-level facade: `init_lib()`, `shutdown_lib()`, `version()`, exports error-code constants + a couple of helpers (`oid_from_hex`, `oid_to_hex`, `check_rc`) |
| `Git::Libgit2::FFI` | the FFI::Platypus instance; every `git_*` binding lives here. POD for the bindings lives in the same file. |
| `Git::Libgit2::Error` | wraps `git_error_last()`. Used by consumers to turn libgit2 error codes into structured info; **not** thrown here. The `klass` field (git_error_t category) is decoded properly — don't roll your own `0` placeholder. |

## Opaque-handle ownership (the single most-violated rule)

Opaque libgit2 handles (`git_repository *`, `git_blob *`, `git_treebuilder *`,
`git_remote *`, …) are exposed as `opaque` pointers via FFI::Platypus. **Every
`*_new` / `*_lookup` MUST be matched with the corresponding `*_free`** by the
caller. This module does not track lifetimes and will not warn if you forget.

The high-level `Git::Native` wrapper does this via Moo `DESTROY`. If you write
ad-hoc test code that calls `git_repository_open_ext`, you are responsible for
the matching `git_repository_free`.

## Bindings — where they live

All binding work happens in `lib/Git/Libgit2/FFI.pm`:

1. **Register new opaque types** near the top of `ffi()` in the
   `$ffi->type( 'opaque' => 'git_xxx' )` block.
2. **Add the `_attach` line** in the matching `# ====` section of `_attach_all()`.
   Use `_attach NAME => [ args ] => ret;`. Keep 2-space indent, no trailing
   commas, align the `=>` columns roughly with neighbours.
3. **Add a `=func NAME` POD block** in the corresponding `=head2` section
   further down (POD order mirrors attach order). One usage line + one short
   paragraph. Mention the matching `*_free` and any out-param.
4. **Add a smoke test** in `t/NN-*.t`. Every test starts with gitconfig isolation
   (see below). When a test commits to `HEAD`, pin the branch right after init
   to avoid sterile-container defaults:
   `check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' )`.

## FFI gotchas already paid for (don't re-pay)

- **`*_options_init`** is preferred over the deprecated `*_init_options` (removed
  in libgit2 1.7+).
- **Opaque out-params that are caller-allocated buffers** (e.g. `git_oid` in
  `git_tag_create`) must be declared `opaque`, NOT `opaque*` — a typo here makes
  the call fail with a misleading "failed to create tag annotation" message.
- **Credential-acquire callback type** is registered as
  `(opaque, string, string, uint, opaque) -> int` — FFI::Platypus closures only
  allow native types, so the `git_credential **out` parameter is passed as a
  plain `opaque` (the pointer value). The closure writes the credential pointer
  into that address via `memcpy`.
- **`git_transport_certificate_check_cb`** — closure type for host-key / TLS
  certificate verification on fetch/push/connect.

## Test isolation contract (this is the trap)

All tests MUST run with:

```perl
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';
```

Without this, libgit2 reads the user's `~/.gitconfig` (the Git::Raw bug).
Side-effects range from surprising defaults to silent test pollution. This is
the single highest-frequency cause of "passes locally, fails in CI" in this repo.

## Test runner gotcha

Plain `prove -l t/` is **not recursive** — it silently skips subdirectory tests.
Use `prove -lr t/` or `dzil test` to run the whole suite. Reserve non-`-r`
`prove -l` for an explicit single file.

## Phase surface (what's bound)

Already bound, against libgit2 1.5.1:

- **Phase 1 MVP** — repo, config, ref, oid, blob, treebuilder, commit, object,
  ref-name validation, remote lookup, error last.
- **Phase 4** — clone, remote fetch/push/connect/ls/disconnect/create,
  fetch/push options init, credential types (userpass/ssh_key/ssh_key_from_agent/
  default/username), transport-certificate-check callback.
- **Phase 5** — revwalk, branch, tag, status, diff, repository_index, set_head,
  strarray.
- **Group A** — `repository_head`/`head_unborn`/`head_detached`,
  `reference_symbolic_*`/`set_target`/`resolve`/`shorthand`/`is_branch`/
  `is_remote`/`is_tag`, `commit_id`/`time`/`time_offset`/`summary`.

Remaining surface is catalogued in `TODO.md` as **Group B** (high-value,
complete-the-CPAN-release: callbacks + `git_buf` out-params) and **Group C**
(blame / describe / submodule / worktree / notes / apply / attr / pathspec /
mailmap — implement on demand).

## Build / release

- `[@Author::GETTY]` Dist::Zilla bundle. `dist.ini` uses `version_finder = :MainModule`.
- `Alien::Libgit2` is the hard runtime dep — must be released first.
- Pure Perl + FFI. No XS, no compiler needed at install time.
- `prove -lr t/` for the suite (recursive). `dzil build` / `dzil test` /
  `dzil release` per the Getty plugin bundle.

## How to add a binding — the canonical recipe

See `TODO.md` § "How to add a binding (recap of the house pattern)" — this
skill is the durable version of that recipe. The TODO file is the per-phase
plan; this skill is the architecture.

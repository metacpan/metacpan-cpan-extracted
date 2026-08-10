---
name: git-native-core
description: Architecture, stack, memory ownership, error handling, and libgit2 quirks specific to the Git::Native CPAN distribution. Load on any Git::Native wrapper edit.
---

# Git::Native — project-specific architecture

The conventions in `CLAUDE.md` are the source of truth. This skill encodes the load-bearing
invariants an implementer must respect when editing the Moo wrappers under `lib/Git/Native/`.
The CLAUDE.md content is non-negotiable — apply silently, do not restate.

## Stack (CLAUDE.md → "Stack")

`Git::Native` (Moo) → `Git::Libgit2` (FFI) → `Alien::Libgit2` (libgit2 C lib).
Touching any of those layers requires going up or down through the same path; never bypass
`Git::Libgit2` to call libgit2 directly from a wrapper.

## Memory ownership (CLAUDE.md → "Memory Ownership")

Each Moo wrapper holds exactly one opaque libgit2 handle. `DESTROY` calls the matching
`git_*_free`. **Child objects** (a `Tree` returned from a `Commit`, a `Reference` returned
from `Repository->head`, etc.) hold a **strong ref to their parent in `_owner`** so the
parent outlives the child — no use-after-free. Pattern to follow when adding a child:

```perl
has _owner => ( is => 'ro', weak_ref => 0 );   # strong — child keeps parent alive
```

`weak_ref => 1` is for the *parent* holding a child when lifetime is shared; the **child**
holding the parent must be a strong ref, otherwise the parent can be freed mid-method and
the child's `git_*_owner` calls segfault.

## Error handling (CLAUDE.md → "Error Handling")

Every FFI call with an `int` return code goes through `check_rc($rc)` from
`Git::Native::Error`. Negative rc → `Git::Libgit2::Error->last` → re-throw as
`Git::Native::Error` (Throwable). Three rules:

1. **Never leak `Git::Libgit2::Error` above this layer.** `t/46-error-paths.t` asserts
   this. A new wrapper method that swallows or rethrows raw libgit2 errors is a regression.
2. **`code` is the primary discriminator** — use the curated `is_*` predicates on
   `Git::Native::Error` (`is_not_found`, `is_auth`, `is_certificate`, …) or compare
   `->code` to the `GIT_E*` constants from `Git::Libgit2`. `klass` (the `git_error_t`
   category) is a secondary signal only.
3. **`check_rc` is exported by `Git::Native::Error`**, not by `Git::Libgit2`. Wrong
   import path = wrong exception type escaping.

## libgit2 quirks that are not negotiable

The following are libgit2 behaviors that other languages (shell-git, JGit, libgit2
older versions) do differently. Each is a footgun for an unwary contributor — read this
list before touching the matching code.

- **Push wildcards are not expanded by libgit2.** `git_remote_push` rejects
  `+refs/karr/*:refs/karr/*` with "not a valid reference". `Git::Native::Remote::push`
  expands patterns client-side via `_owner->reference_names(glob => ...)` and emits one
  concrete refspec per matching local ref. Fetch is unaffected (server-side enumeration).
- **No native `--prune` on push.** Implemented by `_connect(DIRECTION_PUSH)` +
  `git_remote_ls` + diffing remote heads against the expanded local set, then prepending
  `:refs/...` delete refspecs to the push call. `_connect` uses the credential callback,
  so prune works against authenticated remotes.
- **Clone bare is not exposed.** `git_clone_options` embeds two large structs
  (`git_checkout_options`, `git_fetch_options`) before the `bare` field; the offset shifts
  across libgit2 versions. The wrapper errors on `bare => 1` and points users at
  `init(bare=>1) + remote + fetch`. Don't try to add this without a probe of the offsets
  on the supported libgit2 floor (1.5).
- **Clone auth callback not yet plumbed.** Same offset story for the embedded
  `fetch_options.callbacks` pointer. Public HTTPS / git:// / file:// works today.
- **`tag()` returns undef for lightweight tags** — they're plain refs under `refs/tags/*`
  with no annotated object to wrap; use `reference()` instead. Document, don't "fix".
- **`status` uses `git_status_foreach` with a Perl closure** rather than walking
  `git_status_entry` structs by index. Avoids depending on `git_diff_file` layout, which
  grew an extra field in libgit2 1.7.
- **`tag_names()` walks a `git_strarray` via `unpack`** (16 bytes: pointer + count). Stable
  since 1.0 — keep it that way.

## Closure lifetime for the credential callback

`git_credential_acquire_cb` is a `FFI::Platypus::Closure`. The C signature has a
`git_credential **out` out-param — FFI::Platypus closures only accept native types +
strings, so it's declared as plain `opaque` (the pointer value). The Perl closure:

1. Calls the user's coderef.
2. Calls `_disown` on the returned `Git::Native::Credential` to hand ownership to libgit2.
3. `memcpy`s the pointer into the out address.
4. Returning `undef` from the user coderef maps to `GIT_PASSTHROUGH (-30)`, letting libgit2
   try the next auth type.

The closure **must outlive the C call** — `Remote` stashes it in
`$self->{_fetch_keep}` / `_push_keep` / `_connect_keep` for the duration of the operation.
Out-of-scope mid-call = segfault. If you add a new operation that takes credentials,
allocate a `_op_keep` slot.

## Struct size safety margins

For `git_remote_callbacks` / `git_fetch_options` / `git_push_options`, the FFI struct
declarations over-allocate (256 / 384 / 384) vs probed sizes on libgit2 1.5
(120 / 208 / 192). This leaves headroom for newer libgit2 versions that grow the struct
tail. **Field offsets up through `payload` are stable across 1.5 → 1.9.** If you add a
field beyond `payload`, you must probe the offset on every supported libgit2 version
before pinning the layout.

## Test hygiene (CLAUDE.md → "Test Hygiene")

- Every test runs with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null`. Enforced
  in `t/lib/TestRepo.pm`. Do not let a test write to the user's real `~/.gitconfig`.
- Run with `prove -lr t/` (recursive — `prove -l t/` alone skips subdir tests).
- `dzil test` is also recursive.
- Pure-logic helpers (e.g. `Remote::_expand_push_refspecs`, known_hosts host-field
  matching) get their own network-free unit test — `t/43-known-hosts.t`,
  `t/44-push-refspec-expand.t`, `t/45-oid.t`, `t/46-error-paths.t`. Add new pure-logic
  helpers with a matching network-free test alongside.
- Live network tests (`t/40-remote-ssh.t`, `t/41-remote-https.t`) skip unless the matching
  env var is set. Don't make them required.

## Conventions not in CLAUDE.md (project-local)

- **Moo, not Moose.** `has ... => ( is => 'ro', lazy => 1, builder => '_build_x' )` is
  the dominant pattern; `lazy_build => 1` from `perl-core` applies.
- **`namespace::clean`** on every `.pm` (already in cpanfile — every file does this).
- **`# ABSTRACT:`** as the first comment line of every `.pm` (matches house style for
  PodWeaver).
- **Inline `=attr` / `=method` / `=seealso`** PodWeaver directives under the `[@Author::GETTY]`
  bundle. Use the `pod-writer` agent for new modules.
- **`make_immutable` is Moo:** `no Moo;` + `__PACKAGE__->meta->make_immutable;` at the
  bottom of every Moo class file.

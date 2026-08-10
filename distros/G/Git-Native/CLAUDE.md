# Git::Native

High-level Moo wrapper over L<Git::Libgit2>. This is the API CPAN
consumers see. Name contrasts deliberately with `Git::Wrapper` and
`Git::Repository` (both shell out to the `git` binary).

## Stack

`Git::Native` (Moo) -> `Git::Libgit2` (FFI) -> `Alien::Libgit2` (libgit2 C lib).

## Class Layout

```
Git::Native               ->open / ->init($path, bare =>?, initial_branch =>?) / ->clone($url, $path)

Git::Native::Repository   workdir, gitdir, is_bare
                          ->config / ->config_snapshot / ->config_string($k) / ->config_bool($k)
                          ->reference($name), ->reference_names(glob =>)
                          ->reference_create / ->reference_delete / ->reference_exists
                          ->reference_symbolic_create($name, $target, force =>?, message =>?)
                          ->head -> Reference|undef / ->head_unborn / ->head_detached
                          ->set_head($refname)
                          ->remote($name) / ->remote_create / ->remote_anonymous / ->has_remote
                          ->revwalker
                          ->branch($name, type =>) / ->branches(type =>)
                          ->branch_create($name, $target) / ->has_branch
                          ->tag($name) / ->tag_names(pattern =>)
                          ->tag_create($name, $target, message =>?, tagger =>?)
                          ->tag_delete($name)
                          ->status  -> { path => flags, ... }
                          ->status_for_path($path)
                          ->signature_default
                          ->commit_create(tree =>, parents =>, message =>, ...)
                          ->blob_create_frombuffer($scalar)
                          ->object($oid), ->tree($oid), ->tree_builder
                          DESTROY: git_repository_free

Git::Native::Reference    name, shorthand, target -> Oid, symbolic_target, is_symbolic
                          is_branch / is_remote / is_tag
                          ->resolve -> Reference (follows symbolic to direct)
                          ->set_target($oid, message =>?)            (direct refs)
                          ->symbolic_set_target($refname, message =>?) (symbolic refs)
                          ->delete

Git::Native::Config       ->get_string / ->get_bool / ->set_string / ->snapshot

Git::Native::Blob         ->content, ->size, ->oid
Git::Native::Tree         ->entries, ->entry_by_name
Git::Native::TreeBuilder  ->insert(name =>, oid =>, mode => 0100644) / ->write
Git::Native::Commit       ->oid, ->message, ->summary, ->time (epoch), ->time_offset (min)
                          ->tree, ->tree_oid, ->parent_count, ->parent_oids
Git::Native::Remote       ->url, ->name
                          ->fetch(refspecs =>, credentials =>, prune =>)
                          ->push(refspecs =>, credentials =>, prune =>)
                          ->list_refs(credentials =>)
Git::Native::Credential   ->userpass / ->ssh_key / ->ssh_agent / ->default / ->username

Git::Native::Revwalker    ->push_head / ->push_ref / ->push_oid / ->push_glob / ->push_range
                          ->hide_head / ->hide_ref / ->hide_oid / ->hide_glob
                          ->sorting / ->reset / ->simplify_first_parent
                          ->next  -> Oid | undef    ->all  -> [Oid, ...]
Git::Native::Branch       ->name / ->refname / ->target / ->is_head / ->is_local / ->is_remote
                          ->rename($new) / ->delete
Git::Native::Tag          ->name / ->message / ->target_id   (annotated only)
Git::Native::Signature    name, email, when
Git::Native::Oid          stringify hex, ->raw (20B), ->short(7)
Git::Native::Error        isa Throwable::Error; code, klass, message
                          is_not_found / is_exists / is_auth / is_certificate /
                          is_conflict / is_not_fast_forward / is_unborn_branch / is_invalid_spec
                          check_rc (exported) wraps Git::Libgit2::Error
```

## Memory Ownership

Each Moo wrapper holds one opaque libgit2 handle. `DESTROY` calls the
matching `git_*_free`. Child objects (e.g. a `Tree` returned from a
`Commit`) hold a strong ref to their parent in `_owner` so the parent
outlives the child - no use-after-free.

## Error Handling

Every FFI call with an `int` return code goes through `check_rc($rc)`,
which lives in **`Git::Native::Error`** (every wrapper imports it from there,
NOT from `Git::Libgit2`). On negative rc it pulls libgit2's thread-local
error via `Git::Libgit2::Error->last` and re-throws it as a Throwable
`Git::Native::Error` (`code` / `klass` / `message`). No low-level
`Git::Libgit2::Error` leaks above this layer - `t/46-error-paths.t` asserts
exactly that on real lookups and a symbolic-ref mutator.

For branching on the failure kind, `code` is the discriminator: use the
curated `is_*` predicates (`is_not_found`, `is_auth`, `is_certificate`, ...)
or compare `->code` against the `GIT_E*` constants exported by `Git::Libgit2`.
`klass` (the `git_error_t` category) is decoded by `Git::Libgit2 0.005`
and is a secondary signal, not the primary discriminator.

## Phase 4 - Network + Auth

`Git::Native::Remote` is the hard layer. Two libgit2 quirks worth knowing:

- **Push wildcards are not expanded by libgit2.** `git_remote_push` rejects
  `+refs/karr/*:refs/karr/*` with "not a valid reference". `->push` expands
  patterns client-side via `_owner->reference_names(glob => ...)` and emits
  one concrete refspec per matching local ref. Fetch is unaffected (server
  side enumerates).
- **No native `--prune` on push.** Implemented by `_connect(DIRECTION_PUSH)`
  + `git_remote_ls` + diffing remote heads against the expanded local set,
  then prepending `:refs/...` delete refspecs to the push call. `_connect`
  uses the credential callback too, so prune works against authenticated
  remotes.

The credential callback (`git_credential_acquire_cb`) is a
`FFI::Platypus::Closure`. The C signature has a `git_credential **out`
out-param — FFI::Platypus closures only accept native types + strings, so
it's declared as plain `opaque` (the pointer value). The Perl closure
calls the user's coderef, calls `_disown` on the returned
`Git::Native::Credential` to hand ownership to libgit2, then `memcpy`s
the pointer into the out address. Returning `undef` from the user
coderef maps to `GIT_PASSTHROUGH (-30)`, letting libgit2 try the next
auth type.

The closure must outlive the C call — `Remote` stashes it in
`$self->{_fetch_keep}` / `_push_keep` / `_connect_keep` for the duration
of the operation. Out-of-scope mid-call = segv.

Struct sizes for `git_remote_callbacks` / `git_fetch_options` /
`git_push_options` are over-allocated (256 / 384 / 384) vs probed sizes
on libgit2 1.5 (120 / 208 / 192) — leaves headroom for newer libgit2
versions that grow the struct tail. Field offsets up through `payload`
are stable across 1.5 -> 1.9.

## Test Hygiene

All tests run with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null`
to avoid polluting the user's `~/.gitconfig` (the exact bug Git::Raw
shipped). Enforced in `t/lib/TestRepo.pm`.

`t/20-remote-local.t` covers the Phase 4 surface end-to-end with two
working repos linked through a bare repo over `file://` — wildcard push,
fetch, the PASSTHROUGH credential path, and push `--prune`.

`t/30-revwalk.t`, `t/31-branch.t`, `t/32-tag.t`, `t/33-status.t`,
`t/34-clone.t` cover the Phase 5 general-purpose surface.

`t/40-remote-ssh.t` / `t/41-remote-https.t` are live network tests —
both skip unless `TEST_GIT_NATIVE_SSH_URL` / `TEST_GIT_NATIVE_HTTPS_URL`
is set. CI sets the HTTPS URL to a public repo so every push exercises
the real TLS + ref-listing path. SSH and token-auth need operator-set
env vars locally.

Pure-logic helpers that reimplement git semantics in Perl get their own
network-free unit tests, so a regression shows up without a live remote:
`t/43-known-hosts.t` (known_hosts host-field matching), `t/44-push-refspec-expand.t`
(`Remote::_expand_push_refspecs` — libgit2 doesn't expand push wildcards,
we do). `t/45-oid.t` pins the `Git::Native::Oid` value contract (hex<->raw,
`short`, and the `""`/`eq` overloads — `eq` must match an Oid's hex string).

`t/46-error-paths.t` is the contract test for Error Handling above: it
catches REAL libgit2 failures (missing ref/oid lookups, set_target on a
symbolic ref) and asserts they arrive as a Throwable `Git::Native::Error`
with a negative code, never a leaked `Git::Libgit2::Error`. `t/47-object.t`
covers `Repository->object` dispatch to each typed wrapper;
`t/48-merge-commit.t` builds a real 2-parent merge (the `commit_create`
N-parent path). Status (`t/33`), revwalk (`t/30`), branch `is_head` (`t/31`),
detached HEAD (`t/37`) and fetch `--prune` (`t/20`) were widened from a
single happy path toward error and edge cases.

## Phase 5 - General-purpose Surface

Past karr's MVP. Quirks:

- **Clone bare is not exposed.** `git_clone_options` embeds two large
  structs (`git_checkout_options`, `git_fetch_options`) before the `bare`
  field; the offset shifts across libgit2 versions, so the wrapper errors
  on `bare => 1` and points users at `init(bare=>1) + remote + fetch`.
- **Clone auth callback not yet plumbed.** Same offset story for the
  embedded fetch_options' callbacks pointer. Public HTTPS / git:// /
  file:// works today.
- **`tag()` returns undef for lightweight tags** — they're plain refs
  under `refs/tags/*` with no annotated object to wrap; use `reference()`
  instead.
- **Status uses `git_status_foreach` with a Perl closure** rather than
  walking `git_status_entry` structs by index. Avoids depending on the
  `git_diff_file` layout, which grew an extra field in 1.7.
- **`tag_names()` walks a `git_strarray` via `unpack`** (16 bytes:
  pointer + count). Stable layout since 1.0.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/git-native-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug general local-repo wrappers | `git-native-worker` (default) |
| Remote / Credential / clone / fetch / push / FFI struct margins / live network | `git-native-network-worker` |
| clone / status / tag / tag_names / refname / head / branch (Phase 5 surface) | `git-native-phase5-worker` |
| Write / extend tests | `git-native-test-writer` |
| Pre-release audit (CPAN) | `git-native-release-checker` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`,
shared skills are hardlinked from `~/dev/perl/shared-skills/` and `~/dev/shared-skills/`.

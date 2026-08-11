# Git::Native

High-level Moo wrapper over L<Git::Libgit2>. This is the API CPAN
consumers see. Name contrasts deliberately with `Git::Wrapper` and
`Git::Repository` (both shell out to the `git` binary).

## Stack

`Git::Native` (Moo) -> `Git::Libgit2` (FFI) -> `Alien::Libgit2` (libgit2 C lib).

## Class Layout

```
Git::Native               ->open / ->init($path, bare =>?, initial_branch =>?) / ->clone($url, $path)
                          ->reference_name_is_valid($name)
                          ->set_config_search_path(system|global|xdg|programdata => $dir)
                            process-global libgit2 option, not per-repository

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
                          ->index   -> Index   (re-read from disk on every call)
                          ->signature_default
                          ->commit_create(tree =>, parents =>, message =>, ...)
                          ->blob_create_frombuffer($scalar)
                          ->object($oid), ->tree($oid), ->tree_builder
                          ->object_by_prefix($short_hex)   (4..40 chars, git rev-parse)
                          DESTROY: git_repository_free

Git::Native::Reference    name, shorthand, target -> Oid, symbolic_target, is_symbolic
                          is_branch / is_remote / is_tag
                          ->resolve -> Reference (follows symbolic to direct)
                          ->set_target($oid, message =>?)            (direct refs)
                          ->symbolic_set_target($refname, message =>?) (symbolic refs)
                          ->delete

Git::Native::Config       ->get_string / ->get_bool / ->set_string / ->snapshot

Git::Native::Blob         ->content, ->size, ->oid
Git::Native::Index        ->entrycount, ->find($path), ->find_prefix($prefix)
                          ->has_path($path)          exact entry
                          ->has_prefix($prefix)      raw STRING prefix
                          ->is_tracked_under($path)  `git ls-files -- $path`
                          ->reload(force =>?)        read-only, no add/write
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
Git::Native::Signature    name, email, when, offset
                          ->from_handle($ptr)  adopts a libgit2-allocated
                          git_signature*, copying the fields out of the struct
Git::Native::Oid          stringify hex, ->raw (20B), ->short(7)
Git::Native::Error        isa Throwable::Error; code, klass, message
                          is_not_found / is_exists / is_auth / is_certificate /
                          is_conflict / is_not_fast_forward / is_unborn_branch / is_invalid_spec
                          is_not_matched / is_locked / is_bare_repo / is_ambiguous
                          is_owner_mismatch
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

Not every failure arrives as a `Git::Native::Error`. Argument checks that
never reach libgit2 `croak` instead, deliberately: `Oid->from_hex` /
`from_raw`, `Repository->object_by_prefix` (too-short prefix),
`Repository->commit_create` (missing `tree` / `message`). The rule is that a
`->code` is only ever a code libgit2 actually returned — inventing one would
make `is_invalid_spec` ambiguous between "your refname is bad" and "your OID
string is bad" within a single call. `Oid` sets `@CARP_NOT` so the croak
blames the caller's line rather than a line inside the distribution.

**The ownership check does not surface as `GIT_EOWNER` by default.** libgit2
validates that the repository's worktree is owned by the current user
(CVE-2022-24765 analogue). Measured on 1.5.1: with a non-matching
`safe.directory` entry `open` fails `GIT_EOWNER` (-36, `is_owner_mismatch`),
but with **no `safe.directory` entry at all** — the normal state — libgit2
asks the config for the multivar, gets `GIT_ENOTFOUND` back and returns
*that*. So the CI/container case reports a not-found naming a config key the
user never set, and `is_not_found` answers, not `is_owner_mismatch`. Also on
1.5.1: `safe.directory = *` is not honoured. Pinned in `t/72-owner-mismatch.t`,
which reproduces a real `GIT_EOWNER` unprivileged by pointing `core.worktree`
at a root-owned system directory — user namespaces cannot do it, an
unprivileged namespace may map only your own uid.

## Phase 4 - Network + Auth

`Git::Native::Remote` is the hard layer. Two libgit2 quirks worth knowing:

- **Push wildcards are not expanded by libgit2.** `git_remote_push` rejects
  `+refs/karr/*:refs/karr/*` with "not a valid reference". `->push` expands
  patterns client-side via `_owner->reference_names(glob => ...)` and emits
  one concrete refspec per matching local ref. Fetch is unaffected (server
  side enumerates).
- **No native `--prune` on push.** Implemented by `_connect` + `git_remote_ls`
  + diffing remote heads against the expanded local set, then prepending
  `:refs/...` delete refspecs to the push call. `_connect` uses the credential
  callback too, so prune works against authenticated remotes. It connects with
  `GIT_DIRECTION_FETCH` even on the push path (`Remote.pm:178`, the only
  `_connect` call site): `git_remote_ls` needs the ref advertisement, which is
  what upload-pack serves. `GIT_DIRECTION_PUSH` is imported but unused. The
  distinction would only matter against a remote granting write without read
  (karr ticket 23).

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

`t/lib/TestRepo.pm` keeps the user's git config out of the suite (the exact
bug Git::Raw shipped). It takes three mechanisms, because each one reaches
somewhere the others do not:

- `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null` reaches the
  **git CLI** that fixtures shell out to. libgit2 does not know those
  variables at all, nor `GIT_CONFIG_NOSYSTEM` (all three measured, no effect).
- `Git::Native->set_config_search_path(system => …, programdata => …,
  global => …, xdg => …)` isolates **libgit2 itself**, including the system
  level: `/etc/gitconfig` is compiled in and no environment variable moves it,
  so `git_libgit2_opts(GIT_OPT_SET_SEARCH_PATH)` is the only supported
  override. Needs `Git::Libgit2 0.006` (karr ticket 13).
- The **`HOME` / `XDG_CONFIG_HOME`** redirect in the `BEGIN` block. No longer
  what isolates the config — the search path does that, verified with `HOME`
  left alone. It stays for the *non*-config things a home directory carries:
  `~/.ssh/known_hosts`, which `Git::Native::Remote` verifies hostkeys against,
  and the default key paths in `Git::Native::Credential`. The global/XDG
  search paths point into the same throwaway `HOME`, so "drop a `.gitconfig`
  into `$TestRepo::HOME`" keeps meaning what it did.

Load order still matters, for a different reason than before: the search path
is process-global and applies only to repositories opened **after** it is set
— an already-open repository keeps the config it resolved at open time
(measured). `TestRepo.pm` therefore still refuses to load if `Git::Libgit2` is
already in `%INC`; **always `use TestRepo;` before `use Git::Native;`**.
(The old reason — libgit2 guesses its `HOME`-derived search path once, inside
`git_libgit2_init`, which `use Git::Native` triggers via
`Git::Native::Credential` — is still true, and is why `HOME` alone could never
have covered the system level.)

Isolated: system + programdata + global + XDG. **Not** isolated, on purpose:
the repository level — tests set `user.name`/`user.email` on the repo they
just created and must keep seeing them (`t/67-signature.t` relies on this).

`t/69-config-isolation.t` is the regression test, with a control group at both
levels: it also asserts that a probe config *is* read when it should be, so it
can't pass by isolating nothing. Two of its nine subtests fail if the
`set_config_search_path` call is removed from the fixture; four fail against
the pre-karr-9 fixture.

`t/40-remote-ssh.t` restores `$TestRepo::REAL_HOME` — the live SSH path needs
the operator's real `~/.ssh/known_hosts`, and an empty `HOME` would silently
downgrade hostkey verification to "unknown host, warn and continue". That is
unaffected by the search path: config no longer follows `HOME` at all, so
handing `HOME` back cannot undo the isolation.

`t/20-remote-local.t` covers the Phase 4 surface end-to-end with two
working repos linked through a bare repo over `file://` — wildcard push,
fetch, and push `--prune`. It does *not* cover the credential callback:
libgit2 only invokes it when the transport raises an auth challenge, which
`file://` never does (measured: zero invocations). The callback contract is
pinned network-free in `t/52-credential-callback.t`, which drives
`Remote::_make_credential_thunk` directly.

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

`t/51`–`t/66` are the edge-case layer, added to lift branch coverage from
59% to 81% and condition coverage from 48% to 76% (`cover -report text`
after `HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t/`; the live network
tests are excluded because they skip). They target the failure and boundary
paths rather than statements: every `Error` predicate against every other
predicate's code (`t/51`), the credential-callback contract (`t/52`), binary
blob content with embedded NULs (`t/61`), `open_ext` and the `init` argument
guards (`t/62`), `_known_hosts_match` including `@revoked` / `@cert-authority`
(`t/64`), and `_build_strarray`'s NULL-on-empty meaning "use the configured
refspecs" (`t/66`). Two behaviours found while writing them and pinned as
documented rather than changed: `reference_delete` is idempotent (libgit2
returns 0 for an absent ref, like `git update-ref -d`), unlike `reference()`
and `tag()` which throw not-found.

`t/67`–`t/69` came out of that layer: `signature_default` had no test at all
and was returning placeholder attributes, the credential thunk let a `die`
escape into libgit2's C frames, and the config isolation above did not work.

`t/70-commit-create-args.t` pins the Perl-side argument guards on
`commit_create` — missing/undef `tree` or `message`, and a non-arrayref
`parents` — each asserting the croak names the method *and* the argument, and
that it is a plain croak rather than a `Git::Native::Error` (libgit2 would
otherwise answer a missing `message` with an opaque `invalid argument:
'string'`).

`t/71-object-prefix.t` covers `object_by_prefix`. Two things there are load-
bearing rather than decorative: an odd prefix length (5) catches a
byte-instead-of-nibble reading of the length argument, and the ambiguity case
builds a **real** SHA1 collision — blobs `"blob $i\n"` until two share their
first 4 hex characters (261 of them, deterministic because the content is
fixed) — instead of feeding `is_ambiguous` a synthetic code.

`t/72-owner-mismatch.t` reproduces a real `GIT_EOWNER` without privileges (see
Error Handling above) and uses `safe.directory` as its control group: same
repo, same uid, one config line different — so the first block provably
measures the ownership check and not some unrelated open failure. The
no-entry case is asserted as a `-36`/`-3` disjunction with a `note`, so a
libgit2 that fixes the quirk does not turn the file red.

`t/73-oid-invalid-input.t` pins that the `Oid|hex` convenience croaks rather
than throwing, across all 14 wrappers that accept it. Its load-bearing block
calls `reference_create` twice — once with a bad refname (a real
`GIT_EINVALIDSPEC`, so `is_invalid_spec` is true) and once with a bad OID (a
croak) — and asserts the two stay distinguishable. That is the whole argument
for not throwing, made falsifiable.

`t/51-error-predicates.t`'s matrix now covers all 13 curated predicates, plus
a symbol-table oracle that goes red if a predicate is added to `Error.pm` and
forgotten here. It previously excluded `is_bare_repo` on the grounds that the
real-failure pin in `t/46` says more; that exclusion is reversed on purpose.
The two assertions are different: the real-failure pins (`t/46`, `t/71`,
`t/72`) say which code libgit2 returns for a given situation, the matrix says
each predicate is wired to exactly one code.

`t/74-index.t` covers `Git::Native::Index` and the `Repository->index`
accessor. Three of its twelve subtests are the reason the file exists rather
than decoration: the working tree provably *cannot* answer the question (a
clean clone whose `->status` is `{}` while the index holds three paths, and
`status_for_path` on a directory throwing `-5`), a tracked file deleted from
disk still answering true, and the string-prefix trap (`tasks` true,
`task` false, while `has_prefix('task')` is true). The two staleness subtests
stage a file through the **git CLI** — the only way to write an index from
outside libgit2 while `Index` stays read-only — and `skip_all` with git off
`PATH`. Their assertion order is load-bearing and commented as such: the
shared cached handle means the held-object check must run *before* the
fresh-accessor check, or it measures nothing.

Known gap, deliberate: the `DEMOLISH` `if $self->{_handle}` false branch in
every wrapper is unreachable while `_handle` is `required => 1` — that is
most of the remaining branch misses.

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
- **`object_by_prefix` passes the prefix length in hex characters, not
  bytes.** `git_object_lookup_prefix` takes a full-width `git_oid` buffer
  (the prefix zero-padded to 40) plus a nibble count. It also answers a
  prefix shorter than `GIT_OID_MINPREFIXLEN` (4) with `GIT_EAMBIGUOUS` —
  the same code a real ambiguity returns — so the wrapper croaks on a
  too-short prefix before the FFI call and `is_ambiguous` keeps one
  meaning. Needs `Git::Libgit2 0.006` (0.005 has no binding).

## Index

`Git::Native::Index` is read-only on purpose — no `add` / `remove` / `write`.
It exists to answer one question natively that nothing else here can: *is
anything tracked at or below this path?* `status_for_path` cannot, twice over
— it is a working-tree comparison, so it misses a path git tracks but that is
gone from disk, and on a directory it fails `GIT_EAMBIGUOUS` (-5, measured).
The consumer is `App::karr::Git::is_tracked_under`, which shelled out to
`git ls-files -z` for exactly this. Two traps, both pinned in `t/74-index.t`:

- **`find_prefix` matches a string, not a path.** `'tasks'` also matches
  `'tasksfoo.txt'`. The wrapper keeps the two questions apart instead of
  conflating them: `has_prefix` is the raw string question, and
  `is_tracked_under` is the path question — trailing slash stripped, then
  exact-entry match *or* prefix match on `"$path/"`, which is what
  `git ls-files -- $path` answers.
- **libgit2 caches the `git_index*` in the repository.** Every
  `git_repository_index` hands back the *same* object with its refcount
  bumped, so a fresh Perl wrapper alone sees whatever that shared object last
  read — a `git add` by another process would be invisible. `Repository->index`
  therefore calls `git_index_read($idx, 0)` (force 0 = libgit2's stat check,
  free when unchanged) and does not cache Perl-side. Consequence of the shared
  handle: a held Index is not a snapshot either — it picks up the new state
  the moment anyone else calls `->index`. Remove the `git_index_read` line and
  exactly two assertions in `t/74` go red (verified by commenting it out).

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

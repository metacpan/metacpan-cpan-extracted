# TODO — remaining libgit2 surface to bind

This file catalogues the libgit2 1.5.1 functions **not yet** bound in
`lib/Git/Libgit2/FFI.pm`, grouped by family and ordered by value. Group A
(accessor/predicate complements) is **already done** — see the `Group A`
section in `CLAUDE.md`. What's left is split into:

- **Group B** — high-value, want these for a "complete enough" CPAN release.
  Some need new FFI patterns (callbacks, `git_buf` out-params) but each is
  a well-trodden path.
- **Group C** — whole subsystems (blame, describe, submodule, worktree,
  notes, apply, attr/ignore, pathspec, mailmap). Nice-to-have; implement on
  demand.

Bound against **libgit2 1.5.1**. Re-check signatures against the installed
headers (`/usr/include/git2/*.h`) before implementing — Alien::Libgit2 may
ship a different point release.

---

## How to add a binding (recap of the house pattern)

All work happens in `lib/Git/Libgit2/FFI.pm`:

1. **Register any new opaque type** near the top of `ffi()` (the
   `$ffi->type( 'opaque' => 'git_xxx' )` block), e.g. `git_patch`,
   `git_blame`, `git_submodule`, `git_worktree`, `git_note`, `git_mailmap`,
   `git_pathspec`, `git_config_iterator`, `git_index_conflict_iterator`,
   `git_describe_result`.
2. **Add the `_attach` line** in the matching `# ====` section of
   `_attach_all()`. Use `_attach NAME => [ args ] => ret;`. Keep the
   2-space indent, no trailing commas, align the `=>` columns roughly with
   the neighbours.
3. **Add a `=func NAME` POD block** in the corresponding `=head2` section
   further down the file (POD order mirrors attach order). One usage line +
   one short paragraph. Mention the matching `*_free` and any out-param.
4. **Add a smoke test** — either extend the relevant `t/NN-*.t` or add a new
   file. Every test starts with the gitconfig isolation:
   ```perl
   local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
   local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';
   ```
   and, when it commits to `HEAD`, pins the branch right after init:
   ```perl
   check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );
   ```
   (sterile CI containers default to `master` otherwise — this is why the
   existing tests do it).
5. Run `perl -Ilib -c lib/Git/Libgit2/FFI.pm` then
   `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null prove -l t/`.

### FFI type mapping cheat sheet (project conventions)

| C type                         | FFI type        | notes |
|--------------------------------|-----------------|-------|
| `git_xxx *` (opaque handle)    | `git_xxx` alias | registered as `opaque` |
| `git_xxx **out`                | `opaque*`       | caller passes `\my $h` |
| `const char *`                 | `string`        | |
| `char **out` / `const char **` | `string*`       | |
| `const git_oid *` (return)     | `opaque`        | wrap with `oid_to_hex` |
| `const git_oid *` (input)      | `opaque`        | pass a `scalar_to_buffer` ptr |
| `git_time_t` (int64)           | `sint64`        | |
| `size_t` / `size_t *`          | `size_t` / `size_t*` | |
| `int *out`, `unsigned int *out`| `int*` / `uint*`| |
| options struct `*`             | `opaque`        | see "options_init" below |

`oid_to_hex` / `oid_from_hex` are exported by `Git::Libgit2`. `check_rc`
throws on negative return codes. `scalar_to_buffer` comes from
`FFI::Platypus::Buffer`.

---

## The four cross-cutting gotchas

These recur across Group B/C. Read once.

### 1. Callbacks — closures may only use NATIVE types

`FFI::Platypus` closures cannot take struct-by-value or `**` params. The
existing precedent is `git_credential_acquire_cb` and `git_status_cb`
(registered with `$ffi->type( '(...)->int' => 'name' )`). For any new
`*_foreach` / `*_cb`:

- Register the callback type with native params only. Where the C callback
  hands you a `const git_xxx *` pointer, type it as `opaque` and look the
  fields up with separate accessor calls inside the closure.
- Where the C signature has a `**out` you must write back into (rare in
  callbacks), pass it as `opaque` (the raw address) and poke it with
  `FFI::Platypus::Memory` / `memcpy`, exactly as the credential callback
  does (see `Git::Libgit2` for that closure).
- The closure returns `int`; returning non-zero aborts the iteration.

Affected here: `git_diff_foreach` (3 callbacks!), `git_diff_print`,
`git_stash_foreach`, `git_config_foreach`, `git_note_foreach`,
`git_attr_foreach`, `git_submodule_foreach`, `git_blame` has none but
`git_diff_blob_to_buffer` does.

### 2. options structs — bind the `*_options_init` and pass `opaque`

For functions taking `const git_xxx_options *opts`, you do **not** model the
struct in Perl field-by-field for the simple path: allocate a buffer of the
right size, call the already-bound (or newly-bound) `git_xxx_options_init`
to fill defaults, and pass the buffer pointer as `opaque`. Passing `undef`
(NULL) is also valid for most and selects libgit2 defaults — that's what the
existing diff/status/merge tests do. Only bind/marshal individual fields
when a test actually needs to set one. Precedents already in the file:
`git_diff_options_init`, `git_merge_options_init`, `git_checkout_options_init`.

New options_init to add alongside their consumers: `git_blame_options_init`,
`git_describe_options_init` + `git_describe_format_options_init`,
`git_apply_options_init`, `git_worktree_add_options_init`.

### 3. `git_buf` out-params — must be freed with `git_buf_dispose`

Several Group B/C functions return text via `git_buf *out` (a
`{ char *ptr; size_t reserved; size_t size; }` struct). Pattern:

- Allocate a zeroed buffer the size of `git_buf` (3 pointers/size_t →
  24 bytes on 64-bit; safest: `my $buf = "\0" x 24`).
- Pass its address as `opaque`.
- On success read `ptr` + `size` out of the struct (use
  `FFI::Platypus::Record` or manual `unpack` of the pointer, then
  `buffer_to_scalar`).
- **Always** call `git_buf_dispose($buf_ptr)` afterwards. **Bind it** — it
  is not yet in the file. (`git_buf_free` is the deprecated alias; use
  `_dispose`.)

Affected: `git_diff_to_buf`, `git_patch_to_buf`, `git_remote_default_branch`,
`git_branch_upstream_name`/`_remote`/`_merge`, `git_describe_format`,
`git_worktree_is_locked`, `git_message_prettify`.

A clean approach: write one helper in `Git::Libgit2` (e.g. `_slurp_git_buf`)
and reuse it. Consider modelling `git_buf` with `FFI::Platypus::Record` once,
rather than hand-unpacking each time.

### 4. `git_strarray` / `git_oidarray` out-params

`git_strarray { char **strings; size_t count; }`. Functions that fill one
(`git_remote_list`, `git_worktree_list`, the already-bound
`git_tag_list`) need the array read out then freed with the already-bound
`git_strarray_free`. The existing tag-list test shows the read-out pattern —
follow it. `git_oidarray` (`git_merge_base_many` already sidesteps it) is
analogous with `git_oidarray_dispose`.

---

## GROUP B — high-value, do these first

### B1. Merge (content-level) — `merge.h`
Already bound: analysis, base, base_many, options_init, annotated_commit_*.
**Missing:**
```
git_merge_trees   => [ 'opaque*', 'git_repository', 'git_tree', 'git_tree', 'git_tree', 'opaque' ] => 'int'  # out git_index**, ancestor/our/their tree, opts
git_merge_commits => [ 'opaque*', 'git_repository', 'git_commit', 'git_commit', 'opaque' ]         => 'int'  # out git_index**, our/their commit, opts
git_merge         => [ 'git_repository', 'opaque', 'size_t', 'opaque', 'opaque' ]                  => 'int'  # their_heads = array of annotated_commit*, merge_opts, checkout_opts
```
- `_trees`/`_commits` produce an in-memory `git_index` (free with the
  already-bound `git_index_free`); great for "would this conflict?" without
  touching the workdir. Test by merging two divergent trees and asserting
  `git_index_has_conflicts` (see B3).
- `git_merge` mutates the workdir + index; opts can be `undef`.
- `their_heads` is a C array of `git_annotated_commit *`. Build it with
  `pack('P', $ptr)` or an `FFI::Platypus::Buffer`; for a single head, an
  array of length 1.

### B2. Diff/patch text — `diff.h`, `patch.h`, `buffer.h`
The single biggest usability gap: callers can currently *enumerate* deltas
but not get a unified-diff string.
```
git_buf_dispose        => [ 'opaque' ]                                  => 'void'   # SEE gotcha #3 — bind first
git_diff_to_buf        => [ 'opaque', 'git_diff', 'int' ]               => 'int'    # out git_buf*, diff, git_diff_format_t
git_diff_print         => [ 'git_diff', 'int', 'git_diff_line_cb', 'opaque' ] => 'int'  # format, callback, payload — gotcha #1
git_diff_foreach       => [ 'git_diff', 'cb', 'cb', 'cb', 'cb', 'opaque' ]   => 'int'  # file/binary/hunk/line callbacks — gotcha #1
git_patch_from_diff    => [ 'opaque*', 'git_diff', 'size_t' ]           => 'int'    # out git_patch**, diff, delta idx
git_patch_to_buf       => [ 'opaque', 'git_patch' ]                     => 'int'    # out git_buf*
git_patch_num_hunks    => [ 'git_patch' ]                               => 'size_t'
git_patch_get_hunk     => [ 'opaque*', 'size_t*', 'git_patch', 'size_t' ] => 'int'  # out hunk*, lines_in_hunk, patch, hunk idx
git_patch_num_lines_in_hunk => [ 'git_patch', 'size_t' ]               => 'int'
git_patch_free         => [ 'git_patch' ]                               => 'void'
```
- **Easiest win:** bind only `git_buf_dispose` + `git_diff_to_buf`. That
  alone gives a full `git diff` string. The callbacks (`_print`,
  `_foreach`) and the `git_patch_*` family are for hunk-level inspection —
  defer unless needed.
- `git_diff_format_t`: `0=PATCH, 1=PATCH_HEADER, 3=RAW, 4=NAME_ONLY,
  5=NAME_STATUS, 6=PATCH_ID`.
- Register `git_patch` as an opaque type.
- Test: build a tree-to-tree diff (already possible), `git_diff_to_buf`,
  assert the string contains the expected `+`/`-` lines and `@@` hunk header.

### B3. Index conflicts + path lookup — `index.h`
```
git_index_get_bypath        => [ 'git_index', 'string', 'int' ]   => 'opaque'  # returns const git_index_entry*
git_index_has_conflicts     => [ 'git_index' ]                    => 'int'
git_index_conflict_get      => [ 'opaque*', 'opaque*', 'opaque*', 'git_index', 'string' ] => 'int'  # ancestor/our/their entry out
git_index_conflict_add      => [ 'git_index', 'git_index_entry', 'git_index_entry', 'git_index_entry' ] => 'int'
git_index_conflict_remove   => [ 'git_index', 'string' ]          => 'int'
git_index_conflict_cleanup  => [ 'git_index' ]                    => 'int'
git_index_conflict_iterator_new  => [ 'opaque*', 'git_index' ]    => 'int'
git_index_conflict_next     => [ 'opaque*', 'opaque*', 'opaque*', 'git_index_conflict_iterator' ] => 'int'
git_index_conflict_iterator_free => [ 'git_index_conflict_iterator' ] => 'void'
```
- Register `git_index_conflict_iterator` opaque type.
- `git_index_entry` is already a registered opaque alias.
- `get_bypath` stage arg: 0 = normal, 1/2/3 = conflict stages.
- Test: pairs with B1 — `git_merge_trees` two conflicting trees, then
  `git_index_has_conflicts` true + iterate `_conflict_next`.

### B4. Stash iteration + pop — `stash.h`
Already bound: save, apply, drop. **Missing:**
```
git_stash_foreach => [ 'git_repository', 'git_stash_cb', 'opaque' ] => 'int'  # cb: (size_t index, const char* msg, const git_oid* stash_id, void* payload)->int
git_stash_pop     => [ 'git_repository', 'size_t', 'opaque' ]       => 'int'  # index, git_stash_apply_options*
```
- Register `git_stash_cb` as `'(size_t, string, opaque, opaque)->int'`
  (gotcha #1 — `stash_id` is `const git_oid*` → `opaque`).
- `_pop` = apply + drop; opts can be `undef`.
- Test: extend `t/31-stash.t` — save a stash, `_foreach` and collect the
  index/message, then `_pop` and assert the working change is back.

### B5. Branch upstream tracking — `branch.h`
```
git_branch_upstream        => [ 'opaque*', 'git_reference' ]              => 'int'  # out git_reference**
git_branch_set_upstream    => [ 'git_reference', 'string' ]              => 'int'  # branch ref, upstream name (NULL to unset)
git_branch_upstream_name   => [ 'opaque', 'git_repository', 'string' ]   => 'int'  # out git_buf*, refname — gotcha #3
git_branch_upstream_remote => [ 'opaque', 'git_repository', 'string' ]   => 'int'  # out git_buf*
git_branch_upstream_merge  => [ 'opaque', 'git_repository', 'string' ]   => 'int'  # out git_buf*
```
- The `_name`/`_remote`/`_merge` variants write a `git_buf` (gotcha #3).
- Test needs a remote-tracking setup; can reuse the local-remote scaffolding
  in `t/18-remote-local.t`.

### B6. Config — typed accessors + iteration — `config.h`
Currently only `get_string`/`set_string` are bound. Add:
```
git_config_get_bool   => [ 'int*',     'git_config', 'string' ]          => 'int'
git_config_get_int32  => [ 'int32*',   'git_config', 'string' ]          => 'int'   # or sint32
git_config_get_int64  => [ 'sint64*',  'git_config', 'string' ]          => 'int'
git_config_set_bool   => [ 'git_config', 'string', 'int' ]               => 'int'
git_config_set_int32  => [ 'git_config', 'string', 'sint32' ]            => 'int'
git_config_set_int64  => [ 'git_config', 'string', 'sint64' ]            => 'int'
git_config_delete_entry => [ 'git_config', 'string' ]                    => 'int'
git_config_foreach    => [ 'git_config', 'git_config_foreach_cb', 'opaque' ] => 'int'  # cb: (const git_config_entry*, void*)->int — gotcha #1
git_config_iterator_new      => [ 'opaque*', 'git_config' ]              => 'int'
git_config_iterator_glob_new => [ 'opaque*', 'git_config', 'string' ]    => 'int'
git_config_next       => [ 'opaque*', 'git_config_iterator' ]            => 'int'  # out git_config_entry**
git_config_iterator_free => [ 'git_config_iterator' ]                    => 'void'
```
- Register `git_config_iterator`, `git_config_entry` opaque types.
- The typed get/set are the easy, high-value ones — do those first.
- `git_config_entry` is a struct (`name`, `value`, `level`, …); reading its
  fields from the iterator needs either a Record mapping or manual unpack.
- Test: extend `t/16-config.t` — `set_bool` then `get_bool` round-trip.

### B7. Remote management — `remote.h`
Already bound: lookup, create, create_anonymous, url, name, fetch/push/etc.
**Missing:**
```
git_remote_list            => [ 'opaque', 'git_repository' ]   => 'int'   # out git_strarray* — gotcha #4
git_remote_delete          => [ 'git_repository', 'string' ]   => 'int'
git_remote_rename          => [ 'opaque', 'git_repository', 'string', 'string' ] => 'int'  # out git_strarray* (problem refspecs)
git_remote_set_url         => [ 'git_repository', 'string', 'string' ] => 'int'
git_remote_set_pushurl     => [ 'git_repository', 'string', 'string' ] => 'int'
git_remote_pushurl         => [ 'git_remote' ]                 => 'string'
git_remote_default_branch  => [ 'opaque', 'git_remote' ]       => 'int'   # out git_buf* — gotcha #3, needs live connection
git_remote_refspec_count   => [ 'git_remote' ]                 => 'size_t'
```
- `list`/`set_url`/`delete` are trivial and high-value; do those.
- `_default_branch` requires an active `git_remote_connect` — exercise it
  only in the networked test path (or skip if offline, like the existing
  remote tests gate network access).
- Test: extend `t/18-remote-local.t` — create two remotes, `_list` returns
  both, `_set_url` then `git_remote_url` reflects the change, `_delete`.

---

## GROUP C — whole subsystems, implement on demand

Each is self-contained. Same patterns; flagged gotchas only.

### C1. Blame — `blame.h`
`git_blame_options_init`, `git_blame_file` (out `git_blame**`, repo, path,
opts), `git_blame_buffer`, `git_blame_get_hunk_count` (→`uint32`),
`git_blame_get_hunk_byindex`/`_byline` (→ `const git_blame_hunk*`, an opaque
to read fields off), `git_blame_free`. Register `git_blame`. The hunk struct
carries `final_commit_id`, line ranges, signature — reading those needs a
Record or accessor unpack. **Gotcha #2** (options).

### C2. Describe — `describe.h`
`git_describe_options_init`, `git_describe_format_options_init`,
`git_describe_commit` (out `git_describe_result**`, `git_object*`, opts),
`git_describe_workdir`, `git_describe_format` (out `git_buf*`, result,
format_opts — **gotcha #3**), `git_describe_result_free`. Register
`git_describe_result`. Gives `git describe` (tag-relative names). **Gotcha
#2 + #3.**

### C3. Submodule — `submodule.h` (~34 fns)
`git_submodule_lookup`, `git_submodule_foreach` (**gotcha #1**),
`git_submodule_add_setup`/`_add_finalize`, `git_submodule_init`,
`git_submodule_update`/`_update_options_init`, `git_submodule_open`,
`git_submodule_name`/`_path`/`_url` (→ `string`),
`git_submodule_head_id`/`_index_id`/`_wd_id` (→ `const git_oid*` → opaque),
`git_submodule_status`, `git_submodule_free`. Register `git_submodule`.
Large surface — bind lookup/name/path/url/status/foreach/free first.

### C4. Worktree — `worktree.h`
`git_worktree_list` (strarray — **gotcha #4**), `git_worktree_lookup`,
`git_worktree_open_from_repository`, `git_worktree_validate`,
`git_worktree_add_options_init` (**gotcha #2**), `git_worktree_add`,
`git_worktree_lock`/`_unlock`, `git_worktree_is_locked` (out `git_buf*` for
reason — **gotcha #3**), `git_worktree_free`. Register `git_worktree`.

### C5. Notes — `notes.h`
`git_note_read` (out `git_note**`, repo, notes_ref, oid),
`git_note_create`, `git_note_remove`, `git_note_message` (→ `string`),
`git_note_id`/`_author`/`_committer` (→ opaque/sig), `git_note_free`,
`git_note_iterator_new`/`_next`/`_iterator_free`,
`git_note_foreach` (**gotcha #1**). Register `git_note`,
`git_note_iterator`.

### C6. Apply — `apply.h`
`git_apply_options_init` (**gotcha #2**), `git_apply` (repo, `git_diff*`,
location, opts), `git_apply_to_tree` (out `git_index**`, repo, preimage
tree, diff, opts). Pairs with B2 (patch parsing).

### C7. Attr / Ignore — `attr.h`, `ignore.h`
`git_attr_get` (out `const char**`, repo, flags, path, name),
`git_attr_value` (→ `git_attr_value_t` enum classifying the returned
string), `git_attr_foreach` (**gotcha #1**).
`git_ignore_add_rule`, `git_ignore_clear_internal_rules`,
`git_ignore_path_is_ignored` (out `int*`, repo, path) — the last is the
useful one and trivial.

### C8. Pathspec — `pathspec.h`
`git_pathspec_new` (out `git_pathspec**`, `git_strarray*` of patterns),
`git_pathspec_matches_path` (ps, flags, path → int),
`git_pathspec_match_workdir`/`_match_tree`/`_match_index` (out
`git_pathspec_match_list**`), `git_pathspec_free`. Register `git_pathspec`
(+ `git_pathspec_match_list` if matching lists are needed). `_matches_path`
alone is a cheap, useful glob tester.

### C9. Mailmap — `mailmap.h`
`git_mailmap_new`, `git_mailmap_from_repository` (out `git_mailmap**`,
repo), `git_mailmap_resolve` (out `const char** real_name`,
`** real_email`, mailmap, name, email), `git_mailmap_resolve_signature`
(out `git_signature**`), `git_mailmap_free`. Register `git_mailmap`.

---

## Suggested order

1. **B2 minimal** (`git_buf_dispose` + `git_diff_to_buf`) — biggest bang.
2. **B6 typed config** get/set bool/int — trivial, widely useful.
3. **B7** remote list/set_url/delete — trivial.
4. **B1 + B3** merge_trees/commits + index conflicts — pair them, one test.
5. **B4** stash foreach/pop, **B5** branch upstream.
6. Group C as needed.

Keep `CLAUDE.md`'s surface lists updated as families land, and move each
finished family out of this file.

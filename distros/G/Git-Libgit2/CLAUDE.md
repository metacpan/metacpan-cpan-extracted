# Git::Libgit2

Low-level FFI::Platypus bindings to libgit2, via L<Alien::Libgit2>.

## What It Does

1:1 surface of libgit2's C API exposed as Perl subs. No Moo, no objects,
no error-to-exception translation — that lives one layer up in
`Git::Native`.

Opaque libgit2 handles are exposed as `opaque` pointers (FFI::Platypus
type). Callers are responsible for matching every `*_new`/`*_lookup`
with the corresponding `*_free`. The high-level `Git::Native` wrapper
does this via Moo `DESTROY`.

## Architecture

- `Git::Libgit2` — top-level facade. `init_lib()`, `version()`, type
  registry, exports a few helpers.
- `Git::Libgit2::FFI` — internal `FFI::Platypus` instance with all the
  `attach` calls. Singleton — one FFI per process.
- `Git::Libgit2::Error` — wraps `git_error_last()`. Used by consumers
  to turn libgit2 error codes into structured info; not thrown here.

## Phase 1 MVP Cut (what App::karr needs)

`git_libgit2_init`/`_shutdown`, `git_repository_open_ext`/`_workdir`/`_free`,
`git_config_open_default`, `git_reference_lookup`/`_create`/`_delete`/
`_iterator_new`/`_next`/`_name`/`_target`,
`git_oid_fromstr`/`_tostr`,
`git_blob_create_from_buffer`/`_lookup`/`_rawcontent`/`_rawsize`/`_free`,
`git_treebuilder_new`/`_insert`/`_write`/`_free`,
`git_commit_create`/`_lookup`/`_tree`/`_message`/`_free`,
`git_object_lookup`/`_free`,
`git_reference_name_is_valid`,
`git_remote_lookup`/`_url`,
`git_error_last`.

## Phase 5 General-purpose Surface

Functions added past the karr MVP so this isn't karr-specific on CPAN:

`git_clone`/`_options_init`,
`git_revwalk_*` (new/push/push_head/push_ref/push_glob/push_range/hide*/next/sorting/reset/simplify_first_parent/free),
`git_branch_create`/`_lookup`/`_delete`/`_iterator_new`/`_next`/`_iterator_free`/`_name`/`_is_head`/`_move`,
`git_tag_create`/`_create_lightweight`/`_lookup`/`_delete`/`_list`/`_list_match`/`_target`/`_target_id`/`_message`/`_name`/`_tagger`/`_free`,
`git_status_options_init`/`_foreach`/`_foreach_ext`/`_file`,
`git_diff_options_init`/`_tree_to_tree`/`_tree_to_workdir`/`_tree_to_index`/`_index_to_workdir`/`_num_deltas`/`_get_delta`/`_free`,
`git_repository_index`/`git_index_free`,
`git_repository_set_head`,
`git_strarray_free`.

`*_options_init` is preferred over the deprecated `*_init_options` (the
latter is removed in libgit2 1.7+).

### Group A — accessor/predicate complements

Obvious read-side complements to the existing surface (no new FFI patterns,
all native-type returns):

`git_repository_head`/`_head_unborn`/`_head_detached`,
`git_reference_symbolic_create`/`_symbolic_target`/`_symbolic_set_target`/
`_set_target`/`_resolve`/`_shorthand`/`_is_branch`/`_is_remote`/`_is_tag`,
`git_commit_id`/`_time`/`_time_offset`/`_summary`.

The remaining unbound surface (merge/diff-text/index-conflict/stash-iter/
blame/describe/submodule/worktree/…) is catalogued in `TODO.md` with
per-family FFI gotchas.

## Phase 4 Network + Auth additions

`git_remote_fetch`/`_push`/`_connect`/`_ls`/`_disconnect`/`_create`/`_create_anonymous`,
`git_remote_init_callbacks`,
`git_fetch_options_init`/`git_push_options_init`,
`git_credential_userpass_plaintext_new`/`_ssh_key_new`/`_ssh_key_from_agent`/
`_default_new`/`_username_new`/`_free`.

The credential acquire callback type is registered as
`(opaque, string, string, uint, opaque) -> int` — FFI::Platypus closures
only allow native types, so the `git_credential **out` parameter is passed
as a plain `opaque` (the pointer value). The closure writes the credential
pointer into that address via `memcpy`.

## Build

- `[@Author::GETTY]` Dist::Zilla bundle.
- Dep: `Alien::Libgit2` (must be released first).
- No XS, no compiler needed at install — pure Perl + FFI.

## Tests

Each FFI function gets a smoke test in `t/`. Plus `t/torture-init.t`
hammers init/shutdown in a loop. All tests run with
`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null` to avoid
the Git::Raw bug of polluting the user's `~/.gitconfig`.

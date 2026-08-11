use Test2::V0;

# Import everything the facade exports — the new constant groups must be
# available via :all without per-name imports.
use Git::Libgit2 qw( :all );

# Pin libgit2 away from the user's gitconfig — exact bug Git::Raw shipped.
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

# git_sort_t (include/git2/revwalk.h)
is GIT_SORT_NONE,        0,        'GIT_SORT_NONE';
is GIT_SORT_TOPOLOGICAL, 1,        'GIT_SORT_TOPOLOGICAL (1 << 0)';
is GIT_SORT_TIME,        2,        'GIT_SORT_TIME (1 << 1)';
is GIT_SORT_REVERSE,     4,        'GIT_SORT_REVERSE (1 << 2)';

# git_direction (include/git2/net.h)
is GIT_DIRECTION_FETCH, 0, 'GIT_DIRECTION_FETCH';
is GIT_DIRECTION_PUSH,  1, 'GIT_DIRECTION_PUSH';

# git_branch_t (include/git2/types.h)
is GIT_BRANCH_LOCAL,  1, 'GIT_BRANCH_LOCAL';
is GIT_BRANCH_REMOTE, 2, 'GIT_BRANCH_REMOTE';
is GIT_BRANCH_ALL,    3, 'GIT_BRANCH_ALL (LOCAL | REMOTE)';

# git_filemode_t (include/git2/types.h) — octal literals. Cross-check both
# the octal form and the decimal equivalent to guard against a future
# copy-paste that drops a leading zero.
is GIT_FILEMODE_UNREADABLE,      0,      'GIT_FILEMODE_UNREADABLE';
is GIT_FILEMODE_TREE,            0040000, 'GIT_FILEMODE_TREE (octal)';
is GIT_FILEMODE_TREE,            16384,   'GIT_FILEMODE_TREE (decimal cross-check)';
is GIT_FILEMODE_BLOB,            0100644, 'GIT_FILEMODE_BLOB (octal)';
is GIT_FILEMODE_BLOB,            33188,   'GIT_FILEMODE_BLOB (decimal cross-check)';
is GIT_FILEMODE_BLOB_EXECUTABLE, 0100755, 'GIT_FILEMODE_BLOB_EXECUTABLE (octal)';
is GIT_FILEMODE_BLOB_EXECUTABLE, 33261,   'GIT_FILEMODE_BLOB_EXECUTABLE (decimal cross-check)';
is GIT_FILEMODE_LINK,            0120000, 'GIT_FILEMODE_LINK (octal)';
is GIT_FILEMODE_LINK,            40960,   'GIT_FILEMODE_LINK (decimal cross-check)';
is GIT_FILEMODE_COMMIT,          0160000, 'GIT_FILEMODE_COMMIT (octal)';
is GIT_FILEMODE_COMMIT,          57344,   'GIT_FILEMODE_COMMIT (decimal cross-check)';

# git_status_t (include/git2/status.h)
is GIT_STATUS_CURRENT,          0,     'GIT_STATUS_CURRENT';
is GIT_STATUS_INDEX_NEW,        1,     'GIT_STATUS_INDEX_NEW (1 << 0)';
is GIT_STATUS_INDEX_MODIFIED,   2,     'GIT_STATUS_INDEX_MODIFIED (1 << 1)';
is GIT_STATUS_INDEX_DELETED,    4,     'GIT_STATUS_INDEX_DELETED (1 << 2)';
is GIT_STATUS_INDEX_RENAMED,    8,     'GIT_STATUS_INDEX_RENAMED (1 << 3)';
is GIT_STATUS_INDEX_TYPECHANGE, 16,    'GIT_STATUS_INDEX_TYPECHANGE (1 << 4)';
is GIT_STATUS_WT_NEW,           128,   'GIT_STATUS_WT_NEW (1 << 7)';
is GIT_STATUS_WT_MODIFIED,      256,   'GIT_STATUS_WT_MODIFIED (1 << 8)';
is GIT_STATUS_WT_DELETED,       512,   'GIT_STATUS_WT_DELETED (1 << 9)';
is GIT_STATUS_WT_TYPECHANGE,    1024,  'GIT_STATUS_WT_TYPECHANGE (1 << 10)';
is GIT_STATUS_WT_RENAMED,       2048,  'GIT_STATUS_WT_RENAMED (1 << 11)';
is GIT_STATUS_WT_UNREADABLE,    4096,  'GIT_STATUS_WT_UNREADABLE (1 << 12)';
is GIT_STATUS_IGNORED,          16384, 'GIT_STATUS_IGNORED (1 << 14)';
is GIT_STATUS_CONFLICTED,       32768, 'GIT_STATUS_CONFLICTED (1 << 15)';

# OID sizes and prefix minimum (include/git2/oid.h #defines). RAWSZ/HEXSZ are
# what consumers size their own git_oid buffers with — a wrong value here means
# a short buffer that libgit2 writes past, so assert the literal widths.
is GIT_OID_RAWSZ,        20, 'GIT_OID_RAWSZ (raw SHA-1 bytes)';
is GIT_OID_HEXSZ,        40, 'GIT_OID_HEXSZ (hex digits, no NUL)';
is GIT_OID_HEXSZ, GIT_OID_RAWSZ * 2, 'GIT_OID_HEXSZ is two hex digits per raw byte';
is GIT_OID_MINPREFIXLEN, 4,  'GIT_OID_MINPREFIXLEN';

# The value checks above only prove the names arrive via :all. Importing them
# by name is the claim the ticket is about: both must sit in @EXPORT_OK, not
# merely be defined in the package. Exporter dies on an unexported name.
ok lives { Git::Libgit2->import(qw( GIT_OID_RAWSZ GIT_OID_HEXSZ )) },
  'GIT_OID_RAWSZ / GIT_OID_HEXSZ are importable by name';

# git_libgit2_opt_t (include/git2/common.h) — unnumbered enum, so the value is
# purely positional: SET_SEARCH_PATH is the 6th member (index 5). Asserted here
# and not in t/25-opts.t because a wrong option value there would not show up:
# git_libgit2_opts() would just act on some other option and still return 0.
is GIT_OPT_SET_SEARCH_PATH, 5, 'GIT_OPT_SET_SEARCH_PATH (6th member of git_libgit2_opt_t)';

# git_config_level_t (include/git2/config.h). Same trap: libgit2 accepts every
# level in 1..6 for GIT_OPT_SET_SEARCH_PATH and returns 0, so t/25-opts.t stays
# green even if a level is off by one — while a consumer would blank the wrong
# config level. Only the exact enum values make that call mean anything.
is GIT_CONFIG_LEVEL_PROGRAMDATA,  1, 'GIT_CONFIG_LEVEL_PROGRAMDATA';
is GIT_CONFIG_LEVEL_SYSTEM,       2, 'GIT_CONFIG_LEVEL_SYSTEM';
is GIT_CONFIG_LEVEL_XDG,          3, 'GIT_CONFIG_LEVEL_XDG';
is GIT_CONFIG_LEVEL_GLOBAL,       4, 'GIT_CONFIG_LEVEL_GLOBAL';
is GIT_CONFIG_LEVEL_LOCAL,        5, 'GIT_CONFIG_LEVEL_LOCAL';
is GIT_CONFIG_LEVEL_APP,          6, 'GIT_CONFIG_LEVEL_APP';
is GIT_CONFIG_HIGHEST_LEVEL,     -1, 'GIT_CONFIG_HIGHEST_LEVEL';

done_testing;
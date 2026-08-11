use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc oid_to_hex GIT_ENOTFOUND );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp  = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );

# --- git_repository_index ---
my $index;
check_rc Git::Libgit2::FFI::git_repository_index( \$index, $repo );
ok( $index, 'git_repository_index returned an index handle' );

# --- git_index_entrycount (empty index) ---
my $count = Git::Libgit2::FFI::git_index_entrycount($index);
is( $count, 0, 'git_index_entrycount is 0 for new repo' );

# --- build a blob to stage ---
my $blob_buf = "\0" x 20;
my ($blob_ptr) = scalar_to_buffer($blob_buf);
my ($content_ptr) = scalar_to_buffer("hello index\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob_ptr, $repo, $content_ptr, 12 );

# --- git_index_add_bypath ---
# First create the file in the workdir so add_bypath can find it
my $file_path = "$tmp/testfile.txt";
Path::Tiny->new($file_path)->spew("hello index\n");
check_rc Git::Libgit2::FFI::git_index_add_bypath( $index, 'testfile.txt' );

my $count_after_add = Git::Libgit2::FFI::git_index_entrycount($index);
is( $count_after_add, 1, 'git_index_entrycount is 1 after add_bypath' );

# --- git_index_write ---
check_rc Git::Libgit2::FFI::git_index_write($index);

# --- git_index_write_tree ---
my $tree_oid_buf = "\0" x 20;
my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
check_rc Git::Libgit2::FFI::git_index_write_tree( $tree_oid_ptr, $index );
my $tree_hex = oid_to_hex($tree_oid_ptr);
ok( $tree_hex, 'git_index_write_tree returned a tree OID' );

# --- git_index_find ---
# A second entry, so that a reported position of 0 is an answer and not the
# only value the index can possibly yield: 'aaa.txt' sorts before
# 'testfile.txt', which therefore has to come back at position 1.
Path::Tiny->new("$tmp/aaa.txt")->spew("first in index order\n");
check_rc Git::Libgit2::FFI::git_index_add_bypath( $index, 'aaa.txt' );

my $aaa_pos;
is( Git::Libgit2::FFI::git_index_find( \$aaa_pos, $index, 'aaa.txt' ), 0,
  'git_index_find returned 0 for existing entry' );
is( $aaa_pos, 0, "git_index_find puts 'aaa.txt' at position 0" );

my $find_idx;
is( Git::Libgit2::FFI::git_index_find( \$find_idx, $index, 'testfile.txt' ), 0,
  'git_index_find returned 0 for the second entry' );
is( $find_idx, 1, "git_index_find puts 'testfile.txt' after 'aaa.txt'" );

# Miss: the return code carries the answer. libgit2 leaves the out-param
# untouched, so an unset scalar comes back as 0 -- a valid position.
is( Git::Libgit2::FFI::git_index_find( \my $absent_pos, $index, 'nosuchfile.txt' ),
  GIT_ENOTFOUND, 'git_index_find returns GIT_ENOTFOUND for an untracked path' );
is( $absent_pos, 0, 'position out-param is left at 0 on a miss, so it must not be trusted' );

# at_pos may be NULL for callers that only want the yes/no answer.
is( Git::Libgit2::FFI::git_index_find( undef, $index, 'testfile.txt' ), 0,
  'git_index_find accepts undef (NULL) for at_pos' );

# Put the index back to the single entry the rest of the script expects.
check_rc Git::Libgit2::FFI::git_index_remove_bypath( $index, 'aaa.txt' );

# --- git_index_find_prefix ---
# Own repo: prefix semantics need a nested tree plus the "tasks"/"tasksfoo.txt"
# pair, and the linear index state of the surrounding script must stay put.
my $ptmp = Path::Tiny->tempdir;
my $prepo;
check_rc Git::Libgit2::FFI::git_repository_init( \$prepo, "$ptmp", 0 );
my $pindex;
check_rc Git::Libgit2::FFI::git_repository_index( \$pindex, $prepo );

Path::Tiny->new("$ptmp/tasks/nested")->mkpath;
Path::Tiny->new("$ptmp/README.md")->spew("readme\n");
Path::Tiny->new("$ptmp/tasks/one.md")->spew("one\n");
Path::Tiny->new("$ptmp/tasks/nested/two.md")->spew("two\n");
Path::Tiny->new("$ptmp/tasksfoo.txt")->spew("foo\n");
check_rc Git::Libgit2::FFI::git_index_add_bypath( $pindex, $_ )
  for qw( README.md tasks/one.md tasks/nested/two.md tasksfoo.txt );
is( Git::Libgit2::FFI::git_index_entrycount($pindex), 4, 'prefix repo has 4 index entries' );

# Hit: something is tracked under the tasks/ directory, and the reported
# position is the first entry carrying the prefix in index order.
my $pfx_pos;
is( Git::Libgit2::FFI::git_index_find_prefix( \$pfx_pos, $pindex, 'tasks/' ), 0,
  "git_index_find_prefix returns 0 for 'tasks/'" );
my $nested_pos;
check_rc Git::Libgit2::FFI::git_index_find( \$nested_pos, $pindex, 'tasks/nested/two.md' );
is( $pfx_pos, $nested_pos,
  "git_index_find_prefix reports the first entry under 'tasks/'" );

# Miss: no entry carries the prefix.
is( Git::Libgit2::FFI::git_index_find_prefix( \my $docs_pos, $pindex, 'docs/' ), GIT_ENOTFOUND,
  "git_index_find_prefix returns GIT_ENOTFOUND for 'docs/'" );

# On a miss libgit2 does not touch the out-param, so an unset scalar comes
# back as 0 -- a valid position. Only the return code says whether it is one.
is( $docs_pos, 0, 'position out-param is left at 0 on a miss, so it must not be trusted' );

# at_pos may be NULL: a caller that only wants the yes/no answer passes undef
# and FFI::Platypus hands libgit2 a NULL pointer.
is( Git::Libgit2::FFI::git_index_find_prefix( undef, $pindex, 'tasks/' ), 0,
  'git_index_find_prefix accepts undef (NULL) for at_pos on a hit' );
is( Git::Libgit2::FFI::git_index_find_prefix( undef, $pindex, 'docs/' ), GIT_ENOTFOUND,
  'git_index_find_prefix accepts undef (NULL) for at_pos on a miss' );

# The match is a STRING prefix, not a path prefix. Drop the two tasks/ entries
# so only tasksfoo.txt is left carrying the letters "tasks".
check_rc Git::Libgit2::FFI::git_index_remove_bypath( $pindex, 'tasks/one.md' );
check_rc Git::Libgit2::FFI::git_index_remove_bypath( $pindex, 'tasks/nested/two.md' );

is( Git::Libgit2::FFI::git_index_find_prefix( \my $dir_pos, $pindex, 'tasks/' ), GIT_ENOTFOUND,
  "nothing is tracked under the 'tasks/' directory any more" );

my $trap_pos;
is( Git::Libgit2::FFI::git_index_find_prefix( \$trap_pos, $pindex, 'tasks' ), 0,
  "'tasks' without the trailing slash still matches -- it is a string prefix" );
my $foo_pos;
check_rc Git::Libgit2::FFI::git_index_find( \$foo_pos, $pindex, 'tasksfoo.txt' );
is( $trap_pos, $foo_pos,
  "... and what it matched is the file 'tasksfoo.txt', not a directory" );

Git::Libgit2::FFI::git_index_free($pindex);
Git::Libgit2::FFI::git_repository_free($prepo);

# --- git_index_remove_bypath ---
check_rc Git::Libgit2::FFI::git_index_remove_bypath( $index, 'testfile.txt' );
my $count_after_remove = Git::Libgit2::FFI::git_index_entrycount($index);
is( $count_after_remove, 0, 'git_index_entrycount is 0 after remove_bypath' );

# --- git_index_clear ---
check_rc Git::Libgit2::FFI::git_index_add_bypath( $index, 'testfile.txt' );
check_rc Git::Libgit2::FFI::git_index_clear($index);
is( Git::Libgit2::FFI::git_index_entrycount($index), 0, 'git_index_entrycount is 0 after clear' );

# --- git_index_read (reload from disk) ---
check_rc Git::Libgit2::FFI::git_index_read( $index, 0 );

Git::Libgit2::FFI::git_index_free($index);
Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
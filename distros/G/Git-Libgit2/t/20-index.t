use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc oid_to_hex );
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
my $find_idx_buf = "\0" x 8;
my ($find_idx_ptr) = scalar_to_buffer($find_idx_buf);
my $rc_find = Git::Libgit2::FFI::git_index_find( $find_idx_ptr, $index, 'testfile.txt' );
ok( $rc_find == 0, 'git_index_find returned 0 for existing entry' );
my $find_idx = unpack( 'Q', $find_idx_buf );
is( $find_idx, 0, 'git_index_find returned index 0' );

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
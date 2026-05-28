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
# Pin HEAD to 'main' (sterile CI containers default to 'master' otherwise).
check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );

# Pre-allocate OID buffers
my $b1_buf = "\0" x 20;
my $c1_buf = "\0" x 20;

# --- blob + tree + single commit ---
my ($b1_ptr) = scalar_to_buffer($b1_buf);
my ($c1_content_ptr) = scalar_to_buffer("version 1\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b1_ptr, $repo, $c1_content_ptr, 9 );

my $tb1;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb1, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e1, $tb1, 'file.txt', $b1_ptr, 0100644 );
my $t1_buf = "\0" x 20;
my ($t1_ptr) = scalar_to_buffer($t1_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t1_ptr, $tb1 );
Git::Libgit2::FFI::git_treebuilder_free($tb1);

my $tree1;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree1, $repo, $t1_ptr );
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Tester', 'test@example.invalid', 1715000000, 0 );

my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'first commit', $tree1, 0, undef,
);
my $c1_hex = oid_to_hex($c1_ptr);

Git::Libgit2::FFI::git_tree_free($tree1);
Git::Libgit2::FFI::git_signature_free($sig);

# --- verify HEAD resolves to c1 before reset ---
my $head_before;
check_rc Git::Libgit2::FFI::git_revparse_single( \$head_before, $repo, 'HEAD' );
is( oid_to_hex( Git::Libgit2::FFI::git_object_id($head_before) ), $c1_hex, 'before reset: HEAD is c1' );
Git::Libgit2::FFI::git_object_free($head_before);

# --- git_reset with GIT_RESET_SOFT (1) just moves HEAD ---
my $c1_obj;
check_rc Git::Libgit2::FFI::git_commit_lookup( \$c1_obj, $repo, $c1_ptr );
check_rc Git::Libgit2::FFI::git_reset( $repo, $c1_obj, 1, undef );  # 1 = GIT_RESET_SOFT
Git::Libgit2::FFI::git_commit_free($c1_obj);

# --- verify HEAD is still c1 (soft reset does not change index/workdir) ---
my $head_after;
check_rc Git::Libgit2::FFI::git_revparse_single( \$head_after, $repo, 'HEAD' );
is( oid_to_hex( Git::Libgit2::FFI::git_object_id($head_after) ), $c1_hex, 'after soft reset: HEAD is still c1' );
Git::Libgit2::FFI::git_object_free($head_after);

Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;
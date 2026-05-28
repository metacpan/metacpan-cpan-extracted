use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc oid_to_hex );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp  = Path::Tiny::tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );

# Pre-allocate OID buffers
my $b1_buf = "\0" x 20;
my $c1_buf = "\0" x 20;

# --- tree 1 with blob v1 on branch b1 ---
my ($b1_ptr) = scalar_to_buffer($b1_buf);
my ($c1_content_ptr) = scalar_to_buffer("content v1\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b1_ptr, $repo, $c1_content_ptr, 11 );

my $tb1;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb1, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e1, $tb1, 'a.txt', $b1_ptr, 0100644 );
my $t1_buf = "\0" x 20;
my ($t1_ptr) = scalar_to_buffer($t1_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t1_ptr, $tb1 );
Git::Libgit2::FFI::git_treebuilder_free($tb1);

my $tree1;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree1, $repo, $t1_ptr );
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Tester', 'test@example.invalid', 1715000000, 0 );

# commit 1 on b1 (no parent — two orphan commits have no merge base)
my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/b1', $sig, $sig,
  'UTF-8', 'first commit', $tree1, 0, undef,
);
my $c1_hex = oid_to_hex($c1_ptr);

# --- tree 2 with blob v2 on branch b2 (no parent — independent trees) ---
my $b2_buf = "\0" x 20;
my ($b2_ptr) = scalar_to_buffer($b2_buf);
my ($c2_content_ptr) = scalar_to_buffer("content v2\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b2_ptr, $repo, $c2_content_ptr, 11 );

my $tb2;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb2, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e2, $tb2, 'a.txt', $b2_ptr, 0100644 );
my $t2_buf = "\0" x 20;
my ($t2_ptr) = scalar_to_buffer($t2_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t2_ptr, $tb2 );
Git::Libgit2::FFI::git_treebuilder_free($tb2);

my $tree2;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree2, $repo, $t2_ptr );

my $c2_buf = "\0" x 20;
my ($c2_ptr) = scalar_to_buffer($c2_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c2_ptr, $repo, 'refs/heads/b2', $sig, $sig,
  'UTF-8', 'second commit', $tree2, 0, undef,  # no parent — independent commits
);
my $c2_hex = oid_to_hex($c2_ptr);

Git::Libgit2::FFI::git_tree_free($tree1);
Git::Libgit2::FFI::git_tree_free($tree2);

# --- wire up main to b2 so HEAD resolves ---
my $main_ref;
check_rc Git::Libgit2::FFI::git_reference_create( \$main_ref, $repo, 'refs/heads/main', $c2_ptr, 1, undef );
Git::Libgit2::FFI::git_reference_free($main_ref);

# --- git_annotated_commit_from_ref ---
my $b1_ref;
check_rc Git::Libgit2::FFI::git_reference_lookup( \$b1_ref, $repo, 'refs/heads/b1' );
my $ann_c1;
check_rc Git::Libgit2::FFI::git_annotated_commit_from_ref( \$ann_c1, $repo, $b1_ref );
ok( $ann_c1, 'git_annotated_commit_from_ref returned an annotated commit' );
Git::Libgit2::FFI::git_reference_free($b1_ref);

# --- git_annotated_commit_id ---
my $ann_c1_id = Git::Libgit2::FFI::git_annotated_commit_id($ann_c1);
ok( $ann_c1_id, 'git_annotated_commit_id returned an OID pointer' );

# --- git_merge_base (two orphan commits have no common ancestor — expect non-zero) ---
my $base_buf = "\0" x 20;
my ($base_ptr) = scalar_to_buffer($base_buf);
my $rc_base = Git::Libgit2::FFI::git_merge_base( $base_ptr, $repo, $c1_ptr, $c2_ptr );
ok( $rc_base != 0, "git_merge_base returned non-zero (no merge base for orphan commits)" );

# --- git_annotated_commit_free ---
Git::Libgit2::FFI::git_annotated_commit_free($ann_c1);
Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;
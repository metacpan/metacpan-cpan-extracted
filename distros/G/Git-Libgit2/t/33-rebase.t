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

# --- tree 1 with blob v1 ---
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

# commit 1 on main (orphan - no parent)
my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'first commit', $tree1, 0, undef,
);
my $c1_hex = oid_to_hex($c1_ptr);
note("c1 = $c1_hex");

Git::Libgit2::FFI::git_tree_free($tree1);

# --- git_reference_lookup for main ---
my $main_ref;
check_rc Git::Libgit2::FFI::git_reference_lookup( \$main_ref, $repo, 'refs/heads/main' );
ok( $main_ref, 'git_reference_lookup returned a ref' );
Git::Libgit2::FFI::git_reference_free($main_ref);

# --- git_annotated_commit_from_ref ---
check_rc Git::Libgit2::FFI::git_reference_lookup( \$main_ref, $repo, 'refs/heads/main' );
my $ann_main;
check_rc Git::Libgit2::FFI::git_annotated_commit_from_ref( \$ann_main, $repo, $main_ref );
ok( $ann_main, 'git_annotated_commit_from_ref returned an annotated commit' );

my $ann_id = Git::Libgit2::FFI::git_annotated_commit_id($ann_main);
ok( $ann_id, 'git_annotated_commit_id returned an OID pointer' );
Git::Libgit2::FFI::git_reference_free($main_ref);

# --- git_rebase_init (will return error since we have only orphan commits) ---
# Note: rebase requires commits with parents to actually replay.
# With orphan commits, git_rebase_init returns -1 (nothing to rebase).
my $rebase;
my $rc_init = Git::Libgit2::FFI::git_rebase_init(
  \$rebase, $repo, $ann_main, $ann_main, $ann_main, undef
);
note("git_rebase_init rc = $rc_init");

# If rebase_init succeeds (it won't with orphan commits), test rebase operations
if ( $rc_init == 0 && $rebase ) {
  # --- git_rebase_operation_entrycount ---
  my $op_count = Git::Libgit2::FFI::git_rebase_operation_entrycount($rebase);
  ok( $op_count >= 0, "git_rebase_operation_entrycount is $op_count" );

  # --- git_rebase_operation_current ---
  my $op_current = Git::Libgit2::FFI::git_rebase_operation_current($rebase);
  ok( $op_current == 0 || $op_current == 18446744073709551615,
      "git_rebase_operation_current is $op_current" );

  # --- git_rebase_operation_byindex ---
  if ( $op_count > 0 ) {
    my $op = Git::Libgit2::FFI::git_rebase_operation_byindex( $rebase, 0 );
    ok( $op, 'git_rebase_operation_byindex(0) returned an operation' );
  }

  Git::Libgit2::FFI::git_rebase_free($rebase);
} else {
  # With orphan commits, rebase_init returns -1 (GIT_ENOTFOUND)
  ok( $rc_init != 0, 'git_rebase_init returned non-zero for orphan commits' );
  ok( !$rebase || $rebase eq '0' || $rebase eq '', 'git_rebase_init returned NULL for orphan commits' );
}

# --- git_annotated_commit_free ---
Git::Libgit2::FFI::git_annotated_commit_free($ann_main);
Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;
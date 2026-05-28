use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc oid_to_hex );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );

# Pre-allocate buffers for commits
my @commit_bufs = map { "\0" x 20 } 1 .. 4;

# Helper to create a blob
sub make_blob_oid {
  my ($content) = @_;
  my $buf = "\0" x 20;
  my ($ptr) = scalar_to_buffer($buf);
  my ($content_ptr) = scalar_to_buffer($content);
  check_rc Git::Libgit2::FFI::git_blob_create_from_buffer($ptr, $repo, $content_ptr, length($content));
  return $ptr;
}

# Helper to create a tree
sub make_tree_oid {
  my ($blob_oid_ptr, $filename) = @_;
  my $tb;
  check_rc Git::Libgit2::FFI::git_treebuilder_new(\$tb, $repo, undef);
  check_rc Git::Libgit2::FFI::git_treebuilder_insert(\my $entry, $tb, $filename, $blob_oid_ptr, 0100644);
  my $tree_oid_buf = "\0" x 20;
  my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
  check_rc Git::Libgit2::FFI::git_treebuilder_write($tree_oid_ptr, $tb);
  Git::Libgit2::FFI::git_treebuilder_free($tb);
  return $tree_oid_ptr;
}

# Helper to create a commit with a pre-allocated buffer
sub make_commit_oid {
  my ($branch_name, $msg, $blob_oid_ptr, $filename, $time_offset, $commit_buf) = @_;
  my $tree_oid_ptr = make_tree_oid($blob_oid_ptr, $filename);
  my $tree;
  check_rc Git::Libgit2::FFI::git_tree_lookup(\$tree, $repo, $tree_oid_ptr);
  my $sig;
  check_rc Git::Libgit2::FFI::git_signature_new(\$sig, 'Test', 'test@example.invalid', 1715000000 + $time_offset, 0);
  my ($commit_oid_ptr) = scalar_to_buffer($commit_buf);
  check_rc Git::Libgit2::FFI::git_commit_create(
    $commit_oid_ptr, $repo, "refs/heads/$branch_name", $sig, $sig,
    'UTF-8', $msg, $tree, 0, undef,
  );
  Git::Libgit2::FFI::git_tree_free($tree);
  Git::Libgit2::FFI::git_signature_free($sig);
  return $commit_oid_ptr;
}

# Create 4 commits on separate branches
my $b1_oid = make_blob_oid("msg1\n");
my $c1_oid = make_commit_oid('b1', 'first commit',  $b1_oid, 'msg1.txt', 1, $commit_bufs[0]);

my $b2_oid = make_blob_oid("msg2\n");
my $c2_oid = make_commit_oid('b2', 'second commit', $b2_oid, 'msg2.txt', 2, $commit_bufs[1]);

my $b3_oid = make_blob_oid("msg3\n");
my $c3_oid = make_commit_oid('b3', 'third commit',  $b3_oid, 'msg3.txt', 3, $commit_bufs[2]);

my $b4_oid = make_blob_oid("msg4\n");
my $c4_oid = make_commit_oid('b4', 'fourth commit', $b4_oid, 'msg4.txt', 4, $commit_bufs[3]);

my $c1_hex = oid_to_hex($c1_oid);
my $c2_hex = oid_to_hex($c2_oid);
my $c3_hex = oid_to_hex($c3_oid);
my $c4_hex = oid_to_hex($c4_oid);

# --- git_branch_lookup ---
my $branch;
check_rc Git::Libgit2::FFI::git_branch_lookup(\$branch, $repo, 'b1', 1);
ok($branch, 'branch_lookup found b1');
Git::Libgit2::FFI::git_reference_free($branch);

# --- git_branch_name ---
my $branch_ref;
check_rc Git::Libgit2::FFI::git_branch_lookup(\$branch_ref, $repo, 'b1', 1);
my $branch_name;
check_rc Git::Libgit2::FFI::git_branch_name(\$branch_name, $branch_ref);
is($branch_name, 'b1', 'branch_name returns correct name');
Git::Libgit2::FFI::git_reference_free($branch_ref);

# --- git_branch_is_head ---
my $b2_ref;
check_rc Git::Libgit2::FFI::git_branch_lookup(\$b2_ref, $repo, 'b2', 1);
ok(Git::Libgit2::FFI::git_branch_is_head($b2_ref) == 0, 'b2 is not HEAD initially');
Git::Libgit2::FFI::git_reference_free($b2_ref);

my $b3_ref;
check_rc Git::Libgit2::FFI::git_branch_lookup(\$b3_ref, $repo, 'b3', 1);
ok(!Git::Libgit2::FFI::git_branch_is_head($b3_ref), 'b3 is not HEAD');
Git::Libgit2::FFI::git_reference_free($b3_ref);

# --- git_branch_delete ---
my $b3_for_delete;
check_rc Git::Libgit2::FFI::git_branch_lookup(\$b3_for_delete, $repo, 'b3', 1);
check_rc Git::Libgit2::FFI::git_branch_delete($b3_for_delete);
Git::Libgit2::FFI::git_reference_free($b3_for_delete);

# Verify it's gone
my $rc_del = Git::Libgit2::FFI::git_branch_lookup(\my $deleted, $repo, 'b3', 1);
ok($rc_del != 0, 'branch_delete removes the branch');

# --- git_branch_iterator_new / git_branch_next ---
my $iter;
check_rc Git::Libgit2::FFI::git_branch_iterator_new(\$iter, $repo, 1);
my @branch_names;
my $type_out;
while (1) {
  my $ref;
  my $r = Git::Libgit2::FFI::git_branch_next(\$ref, \$type_out, $iter);
  last if $r != 0;
  my $name;
  check_rc Git::Libgit2::FFI::git_branch_name(\$name, $ref);
  push @branch_names, $name;
  Git::Libgit2::FFI::git_reference_free($ref);
}
Git::Libgit2::FFI::git_branch_iterator_free($iter);

ok((grep { $_ eq 'b1' } @branch_names), 'iterator includes b1');
ok((grep { $_ eq 'b2' } @branch_names), 'iterator includes b2');
ok((grep { $_ eq 'b4' } @branch_names), 'iterator includes b4');
ok((grep { $_ eq 'b3' } @branch_names) == 0, 'iterator does not include b3 (deleted)');
ok(@branch_names == 3, 'iterator returned exactly 3 branches (b1, b2, b4)');

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
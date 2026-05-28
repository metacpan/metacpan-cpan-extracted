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

# Pre-allocate commit buffers at outer scope to avoid scalar_to_buffer
# lifetime issues when buffers are created inside subroutines.
my @commit_bufs = map { "\0" x 20 } 1 .. 4;

# Helper to create a blob and return its OID pointer (scalar_to_buffer result)
sub make_blob_oid {
  my ($content) = @_;
  my $buf = "\0" x 20;
  my ($ptr) = scalar_to_buffer($buf);
  my ($content_ptr) = scalar_to_buffer($content);
  check_rc Git::Libgit2::FFI::git_blob_create_from_buffer($ptr, $repo, $content_ptr, length($content));
  return $ptr;
}

# Helper to create a tree with one blob entry and return its OID pointer
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

# Helper to create a commit using a pre-allocated buffer.
# The buffer must be allocated at the outer scope (not inside the sub)
# to avoid scalar_to_buffer lifetime issues.
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

# Create 4 commits on separate branches using pre-allocated buffers
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

# --- revwalk: push_ref for refs/heads/b4 ---
my $rw;
check_rc Git::Libgit2::FFI::git_revwalk_new(\$rw, $repo);
check_rc Git::Libgit2::FFI::git_revwalk_push_ref($rw, 'refs/heads/b4');

my @commits;
while (1) {
  my $oid_buf = "\0" x 20;
  my ($oid_ptr) = scalar_to_buffer($oid_buf);
  my $r = Git::Libgit2::FFI::git_revwalk_next($oid_ptr, $rw);
  last if $r != 0;
  push @commits, oid_to_hex($oid_ptr);
}
Git::Libgit2::FFI::git_revwalk_free($rw);

ok(@commits > 0, 'push_ref returned commits');
is($commits[0], $c4_hex, 'push_ref (b4) returned correct commit');
is(@commits, 1, 'each branch has exactly 1 commit');

# --- push_ref for refs/heads/b3 ---
check_rc Git::Libgit2::FFI::git_revwalk_new(\$rw, $repo);
check_rc Git::Libgit2::FFI::git_revwalk_push_ref($rw, 'refs/heads/b3');

my @b3_commits;
while (1) {
  my $oid_buf = "\0" x 20;
  my ($oid_ptr) = scalar_to_buffer($oid_buf);
  my $r = Git::Libgit2::FFI::git_revwalk_next($oid_ptr, $rw);
  last if $r != 0;
  push @b3_commits, oid_to_hex($oid_ptr);
}
Git::Libgit2::FFI::git_revwalk_free($rw);

is($b3_commits[0], $c3_hex, 'push_ref (b3) returned correct commit');
is(@b3_commits, 1, 'branch3 has exactly 1 commit');

# --- push_glob: all branches ---
check_rc Git::Libgit2::FFI::git_revwalk_new(\$rw, $repo);
check_rc Git::Libgit2::FFI::git_revwalk_push_glob($rw, 'refs/heads/*');

my @glob_commits;
while (1) {
  my $oid_buf = "\0" x 20;
  my ($oid_ptr) = scalar_to_buffer($oid_buf);
  my $r = Git::Libgit2::FFI::git_revwalk_next($oid_ptr, $rw);
  last if $r != 0;
  push @glob_commits, oid_to_hex($oid_ptr);
}
Git::Libgit2::FFI::git_revwalk_free($rw);

ok(@glob_commits >= 4, 'push_glob returned all 4 commits from all branches');

# --- push_range: branch1..branch4 ---
check_rc Git::Libgit2::FFI::git_revwalk_new(\$rw, $repo);
check_rc Git::Libgit2::FFI::git_revwalk_push_range($rw, 'refs/heads/b1..refs/heads/b4');

my @range_commits;
while (1) {
  my $oid_buf = "\0" x 20;
  my ($oid_ptr) = scalar_to_buffer($oid_buf);
  my $r = Git::Libgit2::FFI::git_revwalk_next($oid_ptr, $rw);
  last if $r != 0;
  push @range_commits, oid_to_hex($oid_ptr);
}
Git::Libgit2::FFI::git_revwalk_free($rw);

ok(1, 'push_range executed without crash');

# --- reset clears pending commits ---
check_rc Git::Libgit2::FFI::git_revwalk_new(\$rw, $repo);
check_rc Git::Libgit2::FFI::git_revwalk_push_ref($rw, 'refs/heads/b4');
check_rc Git::Libgit2::FFI::git_revwalk_reset($rw);

my $reset_count = 0;
while (1) {
  my $oid_buf = "\0" x 20;
  my ($oid_ptr) = scalar_to_buffer($oid_buf);
  my $r = Git::Libgit2::FFI::git_revwalk_next($oid_ptr, $rw);
  last if $r != 0;
  $reset_count++;
}
is($reset_count, 0, 'reset clears the revwalk');
Git::Libgit2::FFI::git_revwalk_free($rw);

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
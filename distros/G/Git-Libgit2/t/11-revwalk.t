#!/usr/bin/env perl
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

# Lifetime rule for scalar_to_buffer: the pointer is only valid while the
# scalar it came from is alive and untouched, so a pointer never crosses a
# scope boundary here. The helpers hand OIDs around as the 20-byte strings
# themselves (the same contract as Git::Libgit2::oid_from_hex) and every
# pointer is taken freshly, in the scope that uses it. This file used to
# return pointers to sub-local buffers instead; that only worked through
# copy-on-write buffer sharing that perl 5.41 changed (perl5 06e421c559,
# via perl5#22704), and t/11 was where it surfaced (GH #1).

# Helper to create a blob and return its raw OID as a 20-byte string
sub make_blob_oid {
  my ($content) = @_;
  my $buf = "\0" x 20;
  my ($ptr) = scalar_to_buffer($buf);
  my ($content_ptr) = scalar_to_buffer($content);
  check_rc Git::Libgit2::FFI::git_blob_create_from_buffer($ptr, $repo, $content_ptr, length($content));
  return $buf;
}

# Helper to create a tree with one blob entry, raw OID string in and out
sub make_tree_oid {
  my ($blob_oid, $filename) = @_;
  my ($blob_oid_ptr) = scalar_to_buffer($blob_oid);
  my $tb;
  check_rc Git::Libgit2::FFI::git_treebuilder_new(\$tb, $repo, undef);
  check_rc Git::Libgit2::FFI::git_treebuilder_insert(\my $entry, $tb, $filename, $blob_oid_ptr, 0100644);
  my $tree_oid_buf = "\0" x 20;
  my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
  check_rc Git::Libgit2::FFI::git_treebuilder_write($tree_oid_ptr, $tb);
  Git::Libgit2::FFI::git_treebuilder_free($tb);
  return $tree_oid_buf;
}

# Helper to create a commit on a branch, returning its raw OID string
sub make_commit_oid {
  my ($branch_name, $msg, $blob_oid, $filename, $time_offset) = @_;
  my $tree_oid = make_tree_oid($blob_oid, $filename);
  my ($tree_oid_ptr) = scalar_to_buffer($tree_oid);
  my $tree;
  check_rc Git::Libgit2::FFI::git_tree_lookup(\$tree, $repo, $tree_oid_ptr);
  my $sig;
  check_rc Git::Libgit2::FFI::git_signature_new(\$sig, 'Test', 'test@example.invalid', 1715000000 + $time_offset, 0);
  my $commit_oid_buf = "\0" x 20;
  my ($commit_oid_ptr) = scalar_to_buffer($commit_oid_buf);
  check_rc Git::Libgit2::FFI::git_commit_create(
    $commit_oid_ptr, $repo, "refs/heads/$branch_name", $sig, $sig,
    'UTF-8', $msg, $tree, 0, undef,
  );
  Git::Libgit2::FFI::git_tree_free($tree);
  Git::Libgit2::FFI::git_signature_free($sig);
  return $commit_oid_buf;
}

# Helper: hex of a raw OID string, pointer taken and used in one scope
sub hex_of {
  my ($oid) = @_;
  my ($ptr) = scalar_to_buffer($oid);
  return oid_to_hex($ptr);
}

# Create 4 commits on separate branches
my $c1_hex = hex_of(make_commit_oid('b1', 'first commit',  make_blob_oid("msg1\n"), 'msg1.txt', 1));
my $c2_hex = hex_of(make_commit_oid('b2', 'second commit', make_blob_oid("msg2\n"), 'msg2.txt', 2));
my $c3_hex = hex_of(make_commit_oid('b3', 'third commit',  make_blob_oid("msg3\n"), 'msg3.txt', 3));
my $c4_hex = hex_of(make_commit_oid('b4', 'fourth commit', make_blob_oid("msg4\n"), 'msg4.txt', 4));

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
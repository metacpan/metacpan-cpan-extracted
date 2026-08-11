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
# git_cherrypick below applies onto HEAD, so HEAD has to name the branch this
# test builds ('master' otherwise, in a sterile container).
check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );

# History this test needs — cherrypick and revert are only observable when
# the picked commit actually changes something relative to its own parent:
#
#   c1 (a.txt)            base, refs/heads/main
#   |\
#   | c2 (a.txt b.txt)    refs/heads/topic — adds b.txt
#   c3 (a.txt c.txt)      refs/heads/main  — adds c.txt
#
# c2 and c3 touch disjoint paths, so picking c2 onto c3 merges cleanly.

# Pre-allocate OID buffers
my $b1_buf = "\0" x 20;
my $b2_buf = "\0" x 20;
my $b3_buf = "\0" x 20;
my $c1_buf = "\0" x 20;
my $c2_buf = "\0" x 20;
my $c3_buf = "\0" x 20;

my ($b1_ptr) = scalar_to_buffer($b1_buf);
my ($b2_ptr) = scalar_to_buffer($b2_buf);
my ($b3_ptr) = scalar_to_buffer($b3_buf);
my ($a_content_ptr) = scalar_to_buffer("content a\n");
my ($b_content_ptr) = scalar_to_buffer("content b\n");
my ($c_content_ptr) = scalar_to_buffer("content c\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b1_ptr, $repo, $a_content_ptr, 10 );
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b2_ptr, $repo, $b_content_ptr, 10 );
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b3_ptr, $repo, $c_content_ptr, 10 );

my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Tester', 'test@example.invalid', 1715000000, 0 );

# --- c1: a.txt only (orphan base commit on main) ---
my $tb1;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb1, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e1, $tb1, 'a.txt', $b1_ptr, 0100644 );
my $t1_buf = "\0" x 20;
my ($t1_ptr) = scalar_to_buffer($t1_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t1_ptr, $tb1 );
Git::Libgit2::FFI::git_treebuilder_free($tb1);

my $tree1;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree1, $repo, $t1_ptr );
my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'first commit', $tree1, 0, undef,
);
Git::Libgit2::FFI::git_tree_free($tree1);
note( 'c1 = ' . oid_to_hex($c1_ptr) );

my $commit1;
check_rc Git::Libgit2::FFI::git_commit_lookup( \$commit1, $repo, $c1_ptr );
ok( $commit1, 'git_commit_lookup returned a commit' );

# git_commit_create takes `const git_commit *parents[]` — pack the handle into
# a pointer-sized buffer and pass that buffer's address. Both children below
# have c1 as their single parent, so one array serves for both.
my $parents_buf = pack( 'J', $commit1 );
my ($parents_ptr) = scalar_to_buffer($parents_buf);

# --- c2: a.txt + b.txt on refs/heads/topic ---
my $tb2;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb2, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e2a, $tb2, 'a.txt', $b1_ptr, 0100644 );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e2b, $tb2, 'b.txt', $b2_ptr, 0100644 );
my $t2_buf = "\0" x 20;
my ($t2_ptr) = scalar_to_buffer($t2_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t2_ptr, $tb2 );
Git::Libgit2::FFI::git_treebuilder_free($tb2);

my $tree2;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree2, $repo, $t2_ptr );
my ($c2_ptr) = scalar_to_buffer($c2_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c2_ptr, $repo, 'refs/heads/topic', $sig, $sig,
  'UTF-8', 'add b.txt', $tree2, 1, $parents_ptr,
);
Git::Libgit2::FFI::git_tree_free($tree2);
note( 'c2 = ' . oid_to_hex($c2_ptr) );

# --- c3: a.txt + c.txt on refs/heads/main ---
my $tb3;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb3, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e3a, $tb3, 'a.txt', $b1_ptr, 0100644 );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e3c, $tb3, 'c.txt', $b3_ptr, 0100644 );
my $t3_buf = "\0" x 20;
my ($t3_ptr) = scalar_to_buffer($t3_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t3_ptr, $tb3 );
Git::Libgit2::FFI::git_treebuilder_free($tb3);

my $tree3;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree3, $repo, $t3_ptr );
my ($c3_ptr) = scalar_to_buffer($c3_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c3_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'add c.txt', $tree3, 1, $parents_ptr,
);
Git::Libgit2::FFI::git_tree_free($tree3);
note( 'c3 = ' . oid_to_hex($c3_ptr) );

my ( $commit2, $commit3 );
check_rc Git::Libgit2::FFI::git_commit_lookup( \$commit2, $repo, $c2_ptr );
check_rc Git::Libgit2::FFI::git_commit_lookup( \$commit3, $repo, $c3_ptr );

# --- git_cherrypick_commit ---
# arg0 is `git_index **out`: the merged index, NOT an OID. Picking c2 (adds
# b.txt) onto c3 (has a.txt + c.txt) yields a.txt + b.txt + c.txt. A conflict
# would show up as extra stage entries, so the count is the cleanliness check.
my $cp_index;
my $rc_cpc = Git::Libgit2::FFI::git_cherrypick_commit(
  \$cp_index, $repo, $commit2, $commit3, 0, undef
);
is( $rc_cpc, 0, 'git_cherrypick_commit merged the topic commit onto main' );
ok( $cp_index, 'git_cherrypick_commit returned a git_index handle' );
is( Git::Libgit2::FFI::git_index_entrycount($cp_index), 3,
  'merged index holds a.txt, b.txt and c.txt, unconflicted' );
Git::Libgit2::FFI::git_index_free($cp_index) if $cp_index;

# `mainline` selects the parent to diff against and must be 0 unless the
# picked commit is a merge — the classic misuse, and libgit2 says so.
my $bad_index;
my $rc_mainline = Git::Libgit2::FFI::git_cherrypick_commit(
  \$bad_index, $repo, $commit2, $commit3, 1, undef
);
isnt( $rc_mainline, 0, 'git_cherrypick_commit rejects mainline=1 for a non-merge commit' );
like(
  Git::Libgit2::Error->last($rc_mainline)->message,
  qr/not a merge commit/,
  'rejection comes from libgit2 as the mainline error'
);
Git::Libgit2::FFI::git_index_free($bad_index) if $bad_index;

# --- git_revert_commit ---
# Reverting c2 on top of c2 undoes 'add b.txt', so a.txt is all that is left.
my $rv_index;
my $rc_revert = Git::Libgit2::FFI::git_revert_commit(
  \$rv_index, $repo, $commit2, $commit2, 0, undef
);
is( $rc_revert, 0, 'git_revert_commit reverted the topic commit onto itself' );
ok( $rv_index, 'git_revert_commit returned a git_index handle' );
is( Git::Libgit2::FFI::git_index_entrycount($rv_index), 1,
  'reverting "add b.txt" leaves a.txt alone in the index' );
Git::Libgit2::FFI::git_index_free($rv_index) if $rv_index;

# --- git_cherrypick ---
# Unlike *_commit this one writes to the index and the working directory, so
# the working directory has to match HEAD first — a fresh repository has the
# commits but no checkout, and the safe checkout inside git_cherrypick would
# report GIT_ECONFLICT against the missing files.
my $co_opts_buf = "\0" x 256;
my ($co_opts_ptr) = scalar_to_buffer($co_opts_buf);
check_rc Git::Libgit2::FFI::git_checkout_options_init( $co_opts_ptr, 1 );
check_rc Git::Libgit2::FFI::git_checkout_head( $repo, $co_opts_ptr );

my $rc_cherrypick = Git::Libgit2::FFI::git_cherrypick( $repo, $commit2, undef );
is( $rc_cherrypick, 0, 'git_cherrypick applied the topic commit onto HEAD' );
ok( -e "$tmp/b.txt", 'git_cherrypick checked b.txt out into the working directory' );
is( ( -e "$tmp/b.txt" ? Path::Tiny->new("$tmp/b.txt")->slurp : '' ), "content b\n",
  'b.txt carries the content from the picked commit' );
ok( -e "$tmp/.git/CHERRY_PICK_HEAD", 'git_cherrypick left the repository in cherry-pick state' );

Git::Libgit2::FFI::git_commit_free($commit3);
Git::Libgit2::FFI::git_commit_free($commit2);
Git::Libgit2::FFI::git_commit_free($commit1);
Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;

#!/usr/bin/env perl
use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $src_path = "$tmp/src";
Path::Tiny->new($src_path)->mkpath;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, $src_path, 0 );
check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );

# --- one tree, shared by every commit ---
my $blob_buf = "\0" x 20;
my ($blob_ptr) = scalar_to_buffer($blob_buf);
my ($content_ptr) = scalar_to_buffer("graph content\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob_ptr, $repo, $content_ptr, 14 );
my $tb;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $entry, $tb, 'graph.txt', $blob_ptr, 0100644 );
my $tree_buf = "\0" x 20;
my ($tree_ptr) = scalar_to_buffer($tree_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_ptr, $tb );
Git::Libgit2::FFI::git_treebuilder_free($tb);
my $tree;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree, $repo, $tree_ptr );
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Grapher', 'graph@example.invalid', 1715000000, 0 );

# Returns the 20-byte oid of a new commit on top of $parent_oid (undef: root),
# updating $ref when given.
sub make_commit {
  my ( $ref, $message, $parent_oid ) = @_;
  my $buf = "\0" x 20;
  my ($ptr) = scalar_to_buffer($buf);
  if ($parent_oid) {
    my ($pptr) = scalar_to_buffer( my $copy = $parent_oid );
    check_rc Git::Libgit2::FFI::git_commit_lookup( \my $parent, $repo, $pptr );
    my $parents_buf = pack( 'J', $parent );
    my ($parents_ptr) = scalar_to_buffer($parents_buf);
    check_rc Git::Libgit2::FFI::git_commit_create(
      $ptr, $repo, $ref, $sig, $sig, 'UTF-8', $message, $tree, 1, $parents_ptr,
    );
    Git::Libgit2::FFI::git_commit_free($parent);
  }
  else {
    check_rc Git::Libgit2::FFI::git_commit_create(
      $ptr, $repo, $ref, $sig, $sig, 'UTF-8', $message, $tree, 0, undef,
    );
  }
  return $buf;
}

# Divergence: base <- local1 <- local2 on main, base <- upstream1 on a side branch.
my $base      = make_commit( 'refs/heads/main',     'base',       undef );
my $local1    = make_commit( 'refs/heads/main',     'local 1',    $base );
my $local2    = make_commit( 'refs/heads/main',     'local 2',    $local1 );
my $upstream1 = make_commit( 'refs/heads/upstream', 'upstream 1', $base );
Git::Libgit2::FFI::git_tree_free($tree);
Git::Libgit2::FFI::git_signature_free($sig);

# --- GRAPH: no handle, both calls take the repository and raw oid pointers ---
my ($base_ptr)      = scalar_to_buffer( my $base_c      = $base );
my ($local2_ptr)    = scalar_to_buffer( my $local2_c    = $local2 );
my ($upstream1_ptr) = scalar_to_buffer( my $upstream1_c = $upstream1 );

my ( $ahead, $behind ) = ( 0, 0 );
check_rc Git::Libgit2::FFI::git_graph_ahead_behind( \$ahead, \$behind, $repo, $local2_ptr, $upstream1_ptr );
is( $ahead,  2, 'git_graph_ahead_behind: local is 2 commits ahead of upstream' );
is( $behind, 1, 'git_graph_ahead_behind: local is 1 commit behind upstream' );

is( Git::Libgit2::FFI::git_graph_descendant_of( $repo, $local2_ptr, $base_ptr ),
  1, 'git_graph_descendant_of: local2 descends from base' );
is( Git::Libgit2::FFI::git_graph_descendant_of( $repo, $base_ptr, $local2_ptr ),
  0, 'git_graph_descendant_of: base is not a descendant of local2' );
is( Git::Libgit2::FFI::git_graph_descendant_of( $repo, $local2_ptr, $upstream1_ptr ),
  0, 'git_graph_descendant_of: diverged branches are unrelated' );
is( Git::Libgit2::FFI::git_graph_descendant_of( $repo, $local2_ptr, $local2_ptr ),
  0, 'git_graph_descendant_of: a commit is not its own descendant' );

# --- CLONE: from the local repository by path, no network ---
# git_clone_options is sized generously; the layout moves between releases, so
# only its leading `unsigned int version` is looked at.
my $opts_buf = "\0" x 512;
my ($opts_ptr) = scalar_to_buffer($opts_buf);
is( unpack( 'L', $opts_buf ), 0, 'options buffer starts zeroed' );
check_rc Git::Libgit2::FFI::git_clone_options_init( $opts_ptr, 1 );
is( unpack( 'L', $opts_buf ), 1, 'git_clone_options_init set the struct version' );

my $dst_path = "$tmp/dst";
my $clone;
check_rc Git::Libgit2::FFI::git_clone( \$clone, $src_path, $dst_path, $opts_ptr );
ok( $clone, 'git_clone returned a repository handle' );
ok( !Git::Libgit2::FFI::git_repository_is_bare($clone), 'clone is a non-bare repository' );
is( Path::Tiny->new("$dst_path/graph.txt")->slurp, "graph content\n", 'clone checked out the working tree' );

check_rc Git::Libgit2::FFI::git_remote_lookup( \my $origin, $clone, 'origin' );
is( Git::Libgit2::FFI::git_remote_url($origin), $src_path, 'clone recorded the source as origin' );
Git::Libgit2::FFI::git_remote_free($origin);

my $head_buf = "\0" x 20;
my ($head_ptr) = scalar_to_buffer($head_buf);
check_rc Git::Libgit2::FFI::git_reference_name_to_id( $head_ptr, $clone, 'refs/heads/main' );
my ($local2_ptr2) = scalar_to_buffer( my $local2_d = $local2 );
check_rc Git::Libgit2::FFI::git_graph_ahead_behind( \$ahead, \$behind, $clone, $head_ptr, $local2_ptr2 );
is( [ $ahead, $behind ], [ 0, 0 ], 'cloned main sits on the source tip' );

Git::Libgit2::FFI::git_repository_free($clone);
Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;

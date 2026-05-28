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

# --- create an initial commit so we have something to dirty ---
my $b1_buf = "\0" x 20;
my ($b1_ptr) = scalar_to_buffer($b1_buf);
my ($c1_content_ptr) = scalar_to_buffer("original content\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b1_ptr, $repo, $c1_content_ptr, 16 );

my $tb1;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb1, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e1, $tb1, 'stashfile.txt', $b1_ptr, 0100644 );
my $t1_buf = "\0" x 20;
my ($t1_ptr) = scalar_to_buffer($t1_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t1_ptr, $tb1 );
Git::Libgit2::FFI::git_treebuilder_free($tb1);

my $tree1;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree1, $repo, $t1_ptr );
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Stasher', 'stash@example.invalid', 1715000000, 0 );

my $c1_buf = "\0" x 20;
my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'initial commit', $tree1, 0, undef,
);
Git::Libgit2::FFI::git_tree_free($tree1);

# --- dirty the workdir: modify the tracked file ---
my $stashfile = "$tmp/stashfile.txt";
Path::Tiny->new($stashfile)->spew("modified content\n");

# --- git_stash_save (flags=0: include workdir changes) ---
my $stash;
my $rc = Git::Libgit2::FFI::git_stash_save( \$stash, $repo, $sig, 'WIP: stashed changes', 0 );
ok( $rc == 0, "git_stash_save returned 0 (rc=$rc)" );
ok( $stash, 'git_stash_save returned a non-NULL stash handle' )
  or diag("stash handle is NULL — may have nothing to stash");

Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;
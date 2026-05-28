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

# --- build a commit with a file in the tree ---
my $blob_buf = "\0" x 20;
my ($blob_ptr) = scalar_to_buffer($blob_buf);
my ($content_ptr) = scalar_to_buffer("checkout content\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob_ptr, $repo, $content_ptr, 17 );

my $tb;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $entry, $tb, 'co_file.txt', $blob_ptr, 0100644 );
my $tree_oid_buf = "\0" x 20;
my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_oid_ptr, $tb );
Git::Libgit2::FFI::git_treebuilder_free($tb);

my $tree;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree, $repo, $tree_oid_ptr );
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Tester', 'test@example.invalid', 1715000000, 0 );
my $commit_buf = "\0" x 20;
my ($commit_ptr) = scalar_to_buffer($commit_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $commit_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'add checkout file', $tree, 0, undef,
);
Git::Libgit2::FFI::git_tree_free($tree);
Git::Libgit2::FFI::git_signature_free($sig);

my $commit_obj;
check_rc Git::Libgit2::FFI::git_commit_lookup( \$commit_obj, $repo, $commit_ptr );

# --- git_checkout_options_init ---
my $opts_buf = "\0" x 256;
my ($opts_ptr) = scalar_to_buffer($opts_buf);
check_rc Git::Libgit2::FFI::git_checkout_options_init( $opts_ptr, 1 );

# --- git_checkout_tree ---
check_rc Git::Libgit2::FFI::git_checkout_tree( $repo, $commit_obj, $opts_ptr );

# --- git_checkout_head ---
# After checkout_tree the index is updated but HEAD still points at commit.
# Use checkout_head to update HEAD as well.
check_rc Git::Libgit2::FFI::git_checkout_head( $repo, $opts_ptr );

# Verify the file exists in the workdir with correct content
my $co_file = "$tmp/co_file.txt";
ok( -e $co_file, 'co_file.txt exists after checkout_head' );
is( Path::Tiny->new($co_file)->slurp, "checkout content\n", 'co_file.txt has correct content' );

Git::Libgit2::FFI::git_commit_free($commit_obj);
Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
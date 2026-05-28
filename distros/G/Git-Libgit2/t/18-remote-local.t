use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

# --- Set up two repos: local working repo + bare "remote" repo ---
my $tmp = Path::Tiny->tempdir;

# The "remote": a bare repo that the local repo will push/fetch from
my $remote_path = "$tmp/remote.git";
Path::Tiny->new($remote_path)->mkpath;
my $remote_repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$remote_repo, $remote_path, 1 );  # bare=1

# The local repo (non-bare)
my $local_path = "$tmp/local";
Path::Tiny->new($local_path)->mkpath;
my $local_repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$local_repo, $local_path, 0 );

# Create a commit in the local repo so we have something to reference
my $blob_buf = "\0" x 20;
my ($blob_ptr) = scalar_to_buffer($blob_buf);
my ($content_ptr) = scalar_to_buffer("hello remote\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob_ptr, $local_repo, $content_ptr, 12 );

my $tb;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $local_repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $entry, $tb, 'hello.txt', $blob_ptr, 0100644 );
my $tree_oid_buf = "\0" x 20;
my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_oid_ptr, $tb );
Git::Libgit2::FFI::git_treebuilder_free($tb);

my $tree;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree, $local_repo, $tree_oid_ptr );
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Local', 'local@example.invalid', 1715000000, 0 );
my $commit_buf = "\0" x 20;
my ($commit_ptr) = scalar_to_buffer($commit_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $commit_ptr, $local_repo, 'HEAD', $sig, $sig,
  'UTF-8', 'push to remote', $tree, 0, undef,
);
Git::Libgit2::FFI::git_tree_free($tree);
Git::Libgit2::FFI::git_signature_free($sig);

# --- git_remote_create ---
my $remote;
check_rc Git::Libgit2::FFI::git_remote_create( \$remote, $local_repo, 'origin', "file://$remote_path" );
ok( $remote, 'git_remote_create returned a remote handle' );

# --- git_remote_name ---
my $remote_name = Git::Libgit2::FFI::git_remote_name($remote);
is( $remote_name, 'origin', 'git_remote_name returned "origin"' );

# --- git_remote_url ---
my $remote_url = Git::Libgit2::FFI::git_remote_url($remote);
like( $remote_url, qr{file://.*remote\.git}, 'git_remote_url contains file://...remote.git' );

# --- git_remote_connect(DIRECTION_FETCH) + disconnect ---
# NOTE: git_remote_ls is NOT tested here because it writes pointers into
# the output buffer that become dangling after git_remote_disconnect.
# The remote's internal head list is freed on disconnect, so using those
# pointers after disconnect causes a use-after-free.
check_rc Git::Libgit2::FFI::git_remote_connect( $remote, 0, 0, 0, 0 );  # 0 = GIT_DIRECTION_FETCH

check_rc Git::Libgit2::FFI::git_remote_disconnect($remote);

# --- git_remote_free ---
Git::Libgit2::FFI::git_remote_free($remote);

# --- git_remote_lookup ---
# Re-look up the remote we just created via git_remote_lookup
my $remote2;
check_rc Git::Libgit2::FFI::git_remote_lookup( \$remote2, $local_repo, 'origin' );
ok( $remote2, 'git_remote_lookup found origin' );
is( Git::Libgit2::FFI::git_remote_name($remote2), 'origin', 'lookup: remote name is origin' );
Git::Libgit2::FFI::git_remote_free($remote2);

# Cleanup
Git::Libgit2::FFI::git_repository_free($local_repo);
Git::Libgit2::FFI::git_repository_free($remote_repo);

shutdown_lib();
done_testing;
use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );

# Build a commit so HEAD exists
my $blob_buf = "\0" x 20;
my ($blob_ptr) = scalar_to_buffer($blob_buf);
my ($content_ptr) = scalar_to_buffer("hello\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob_ptr, $repo, $content_ptr, 5 );

my $tb;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $entry, $tb, 'hello.txt', $blob_ptr, 0100644 );
my $tree_oid_buf = "\0" x 20;
my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_oid_ptr, $tb );
Git::Libgit2::FFI::git_treebuilder_free($tb);

my $tree;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree, $repo, $tree_oid_ptr );
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Test', 'test@example.invalid', 1715000000, 0 );

my $commit_buf = "\0" x 20;
my ($commit_ptr) = scalar_to_buffer($commit_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $commit_ptr, $repo, 'HEAD', $sig, $sig,
  'UTF-8', 'initial commit', $tree, 0, undef,
);
Git::Libgit2::FFI::git_tree_free($tree);
Git::Libgit2::FFI::git_signature_free($sig);

# --- dirty the workdir ---
my $file = "$tmp/newfile.txt";
Path::Tiny->new($file)->spew("new content\n");

# --- git_status_file on newfile (dirty workdir) ---
my $flags_out = 0;
check_rc Git::Libgit2::FFI::git_status_file( \$flags_out, $repo, 'newfile.txt' );
ok( $flags_out == 128, 'git_status_file returned WT_NEW (128) for newfile.txt' );

# --- git_status_file on tracked file ---
my $flags_hello = 0;
check_rc Git::Libgit2::FFI::git_status_file( \$flags_hello, $repo, 'hello.txt' );
ok( $flags_hello >= 0, 'git_status_file returns success for tracked file' );

# --- git_status_file on non-existent file ---
my $flags_absent = 0;
my $r_absent = Git::Libgit2::FFI::git_status_file( \$flags_absent, $repo, 'nonexistent.txt' );
is( $r_absent, -3, 'git_status_file returns -3 for absent file (not an error)' );

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
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

# --- build one commit ---
my $b1_buf = "\0" x 20;
my ($b1_ptr) = scalar_to_buffer($b1_buf);
my ($c1_content_ptr) = scalar_to_buffer("v1\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b1_ptr, $repo, $c1_content_ptr, 3 );

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
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Test', 'test@example.invalid', 1715000000, 0 );

my $c1_buf = "\0" x 20;
my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'first commit', $tree1, 0, undef,
);
my $c1_hex = oid_to_hex($c1_ptr);

Git::Libgit2::FFI::git_tree_free($tree1);

# --- git_reflog_read ---
my $reflog;
check_rc Git::Libgit2::FFI::git_reflog_read( \$reflog, $repo, 'refs/heads/main' );
ok( $reflog, 'git_reflog_read returned a reflog handle' );

# --- git_reflog_entrycount ---
my $count = Git::Libgit2::FFI::git_reflog_entrycount($reflog);
ok( $count >= 1, "reflog entry count is $count (>= 1)" );

# --- git_reflog_entry_byindex ---
my $entry;
if ( $count > 0 ) {
  $entry = Git::Libgit2::FFI::git_reflog_entry_byindex( $reflog, 0 );
  ok( $entry, 'git_reflog_entry_byindex(0) returned an entry' );
}

# --- git_reflog_entry_id_new (takes git_reflog_entry*) ---
my $latest_id = Git::Libgit2::FFI::git_reflog_entry_id_new($entry);
ok( $latest_id, 'git_reflog_entry_id_new returned a pointer' );

# --- git_reflog_entry_message (takes git_reflog_entry*) ---
my $msg = Git::Libgit2::FFI::git_reflog_entry_message($entry);
ok( defined $msg, 'git_reflog_entry_message returned something' );

Git::Libgit2::FFI::git_reflog_free($reflog);
Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;
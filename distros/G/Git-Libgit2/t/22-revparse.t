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

# Pre-allocate OID buffers at outer scope
my $b1_buf = "\0" x 20;
my $c1_buf = "\0" x 20;

# --- blob + tree + single commit ---
my ($b1_ptr) = scalar_to_buffer($b1_buf);
my ($c1_content_ptr) = scalar_to_buffer("content v1\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b1_ptr, $repo, $c1_content_ptr, 11 );

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

my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/main', $sig, $sig,
  'UTF-8', 'first commit', $tree1, 0, undef,
);
my $c1_hex = oid_to_hex($c1_ptr);

Git::Libgit2::FFI::git_tree_free($tree1);
Git::Libgit2::FFI::git_signature_free($sig);

# --- git_revparse_single ---
my $head_obj;
check_rc Git::Libgit2::FFI::git_revparse_single( \$head_obj, $repo, 'HEAD' );
ok( $head_obj, 'git_revparse_single(HEAD) returned an object' );
is( oid_to_hex( Git::Libgit2::FFI::git_object_id($head_obj) ), $c1_hex, 'revparse_single(HEAD) id matches c1' );
is( Git::Libgit2::FFI::git_object_type($head_obj), 1, 'revparse_single(HEAD) type is COMMIT' );
Git::Libgit2::FFI::git_object_free($head_obj);

# Resolve 'main' branch name
my $main_obj;
check_rc Git::Libgit2::FFI::git_revparse_single( \$main_obj, $repo, 'main' );
ok( $main_obj, 'git_revparse_single(main) returned an object' );
is( oid_to_hex( Git::Libgit2::FFI::git_object_id($main_obj) ), $c1_hex, 'revparse_single(main) id matches c1' );
Git::Libgit2::FFI::git_object_free($main_obj);

# Resolve short OID (first 4 chars of c1_hex)
my $short_oid = substr( $c1_hex, 0, 4 );
my $short_obj;
check_rc Git::Libgit2::FFI::git_revparse_single( \$short_obj, $repo, $short_oid );
ok( $short_obj, "git_revparse_single($short_oid) returned an object" );
is( oid_to_hex( Git::Libgit2::FFI::git_object_id($short_obj) ), $c1_hex, "revparse_single(short OID) id matches c1" );
Git::Libgit2::FFI::git_object_free($short_obj);

Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;
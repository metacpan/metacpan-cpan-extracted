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

# --- build a standalone commit (no parents) ---
my $blob1_buf = "\0" x 20;
my ($blob1_ptr) = scalar_to_buffer($blob1_buf);
my ($content1_ptr) = scalar_to_buffer("content\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob1_ptr, $repo, $content1_ptr, 7 );

my $tb1;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb1, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e1, $tb1, 'file.txt', $blob1_ptr, 0100644 );
my $tree1_buf = "\0" x 20;
my ($tree1_ptr) = scalar_to_buffer($tree1_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree1_ptr, $tb1 );
Git::Libgit2::FFI::git_treebuilder_free($tb1);

my $tree1;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree1, $repo, $tree1_ptr );
my $sig1;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig1, 'Author', 'author@example.invalid', 1715000000, 0 );
my $c1_buf = "\0" x 20;
my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/main', $sig1, $sig1,
  'UTF-8', 'initial commit', $tree1, 0, undef,
);
my $c1_hex = oid_to_hex($c1_ptr);
Git::Libgit2::FFI::git_tree_free($tree1);
Git::Libgit2::FFI::git_signature_free($sig1);

# --- git_object_lookup ---
my $obj;
check_rc Git::Libgit2::FFI::git_object_lookup( \$obj, $repo, $c1_ptr, -2 );  # -2 = GIT_OBJECT_ANY
ok( $obj, 'git_object_lookup returned an object handle' );
is( Git::Libgit2::FFI::git_object_type($obj), 1, 'object_type is GIT_OBJECT_COMMIT (1)' );
is( oid_to_hex( Git::Libgit2::FFI::git_object_id($obj) ), $c1_hex, 'object_id matches commit OID' );
Git::Libgit2::FFI::git_object_free($obj);

# --- git_commit_lookup ---
my $commit;
check_rc Git::Libgit2::FFI::git_commit_lookup( \$commit, $repo, $c1_ptr );
ok( $commit, 'git_commit_lookup returned a commit handle' );

# --- git_commit_message ---
is( Git::Libgit2::FFI::git_commit_message($commit), 'initial commit', 'git_commit_message returns correct message' );

# --- git_commit_tree ---
my $tree_out;
check_rc Git::Libgit2::FFI::git_commit_tree( \$tree_out, $commit );
ok( $tree_out, 'git_commit_tree returned a tree handle' );
Git::Libgit2::FFI::git_tree_free($tree_out);

# --- git_commit_parentcount ---
is( Git::Libgit2::FFI::git_commit_parentcount($commit), 0, 'git_commit_parentcount returns 0 for initial commit' );

# --- git_commit_parent_id on initial commit (no parents) ---
# git_commit_parent_id returns a NULL opaque pointer for non-existent parents
my $p_id = Git::Libgit2::FFI::git_commit_parent_id($commit, 0);
ok( !$p_id, 'git_commit_parent_id(commit, 0) is NULL for initial commit' );

# --- git_commit_author / git_commit_committer ---
my $author_sig = Git::Libgit2::FFI::git_commit_author($commit);
ok( $author_sig, 'git_commit_author returned a signature handle' );

my $committer_sig = Git::Libgit2::FFI::git_commit_committer($commit);
ok( $committer_sig, 'git_commit_committer returned a signature handle' );

# NOTE: git_commit_author/committer return borrowed pointers into commit memory.
# Do NOT call git_signature_free on them (they are not allocated).

Git::Libgit2::FFI::git_commit_free($commit);

# --- git_blob_rawcontent ---
my $blob_content_buf = "\0" x 20;
my ($blob_content_ptr) = scalar_to_buffer($blob_content_buf);
my ($raw_content_ptr) = scalar_to_buffer("hello world\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer(
  $blob_content_ptr, $repo, $raw_content_ptr, 12,
);

my $blob_obj;
check_rc Git::Libgit2::FFI::git_blob_lookup( \$blob_obj, $repo, $blob_content_ptr );
ok( $blob_obj, 'git_blob_lookup returned a blob handle' );

is( Git::Libgit2::FFI::git_blob_rawsize($blob_obj), 12, 'git_blob_rawsize returned 12' );

# rawcontent returns an opaque pointer (const char * in C).
# Use FFI::Platypus cast to convert it to a string.
my $content_ptr = Git::Libgit2::FFI::git_blob_rawcontent($blob_obj);
my $raw_bytes = Git::Libgit2::FFI::ffi()->cast( 'opaque', 'string', $content_ptr );
is( $raw_bytes, "hello world\n", 'git_blob_rawcontent returned correct content' );

Git::Libgit2::FFI::git_blob_free($blob_obj);

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
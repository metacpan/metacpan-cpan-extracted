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

# Pre-allocate buffers for commits
my @commit_bufs = map { "\0" x 20 } 1 .. 4;

# Helper to create a blob - returns the pointer (from scalar_to_buffer)
sub make_blob {
  my ($content) = @_;
  my $buf = "\0" x 20;
  my ($ptr) = scalar_to_buffer($buf);
  my ($content_ptr) = scalar_to_buffer($content);
  check_rc Git::Libgit2::FFI::git_blob_create_from_buffer($ptr, $repo, $content_ptr, length($content));
  return $ptr;
}

# Helper to create a tree - returns the pointer (from scalar_to_buffer)
sub make_tree {
  my ($blob_oid_ptr, $filename) = @_;
  my $tb;
  check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $repo, undef );
  check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $entry, $tb, $filename, $blob_oid_ptr, 0100644 );
  my $tree_oid_buf = "\0" x 20;
  my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
  check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_oid_ptr, $tb );
  Git::Libgit2::FFI::git_treebuilder_free($tb);
  return $tree_oid_ptr;
}

# Helper to create a commit - returns the pointer (from scalar_to_buffer)
sub make_commit {
  my ($branch_name, $msg, $blob_oid_ptr, $filename, $time_offset, $commit_buf) = @_;
  my $tree_oid_ptr = make_tree($blob_oid_ptr, $filename);
  my $tree;
  check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree, $repo, $tree_oid_ptr );
  my $sig;
  check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Test', 'test@example.invalid', 1715000000 + $time_offset, 0 );
  my ($commit_oid_ptr) = scalar_to_buffer($commit_buf);
  check_rc Git::Libgit2::FFI::git_commit_create(
    $commit_oid_ptr, $repo, "refs/heads/$branch_name", $sig, $sig,
    'UTF-8', $msg, $tree, 0, undef,
  );
  Git::Libgit2::FFI::git_tree_free($tree);
  Git::Libgit2::FFI::git_signature_free($sig);
  return $commit_oid_ptr;
}

# Create commits to tag
my $b1_buf = make_blob("msg1\n");
my $c1_buf = make_commit( 'b1', 'first commit',  $b1_buf, 'msg1.txt', 1, $commit_bufs[0] );

my $b2_buf = make_blob("msg2\n");
my $c2_buf = make_commit( 'b2', 'second commit', $b2_buf, 'msg2.txt', 2, $commit_bufs[1] );

my $c1_hex = oid_to_hex($c1_buf);
my $c2_hex = oid_to_hex($c2_buf);

# --- git_reference_create (lightweight tag) ---
my $tag1_buf_raw = "\0" x 20;
my ($tag1_buf) = scalar_to_buffer($tag1_buf_raw);
check_rc Git::Libgit2::FFI::git_reference_create(
  $tag1_buf, $repo, 'refs/tags/v1.0-lightweight', $c1_buf, 0, 'lightweight tag',
);
like( oid_to_hex($tag1_buf), qr/\A[0-9a-f]{40}\z/, 'lightweight tag created via reference_create' );

# --- git_tag_lookup (lightweight tags are refs, not ODB objects — look up by ref) ---
my $tag1_ref;
check_rc Git::Libgit2::FFI::git_reference_lookup( \$tag1_ref, $repo, 'refs/tags/v1.0-lightweight' );
ok( $tag1_ref, 'reference_lookup found lightweight tag ref' );
Git::Libgit2::FFI::git_reference_free($tag1_ref);

# --- git_tag_delete ---
check_rc Git::Libgit2::FFI::git_tag_delete( $repo, 'v1.0-lightweight' );
my $rc_del = Git::Libgit2::FFI::git_reference_lookup( \my $deleted_ref, $repo, 'refs/tags/v1.0-lightweight' );
ok( $rc_del != 0, 'tag_delete removes the ref' );

# --- git_tag_create_from_buffer (annotated tag) ---
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Tagger', 'tagger@example.invalid', 1715000000, 0 );

my $tag2_buffer = "object $c2_hex\n" .
                  "type commit\n" .
                  "tag v2.0-annotated\n" .
                  "tagger Tagger <tagger\@example.invalid> 1715000000 +0000\n" .
                  "\nThis is an annotated tag message\n";

my $tag2_buf_raw = "\0" x 20;
my ($tag2_buf) = scalar_to_buffer($tag2_buf_raw);
check_rc Git::Libgit2::FFI::git_tag_create_from_buffer( $tag2_buf, $repo, $tag2_buffer, 0 );
like( oid_to_hex($tag2_buf), qr/\A[0-9a-f]{40}\z/, 'annotated tag created via git_tag_create_from_buffer' );

# --- git_tag_lookup (annotated tag) ---
my $tag2_obj;
check_rc Git::Libgit2::FFI::git_tag_lookup( \$tag2_obj, $repo, $tag2_buf );
ok( $tag2_obj, 'tag_lookup found annotated tag' );

# --- git_tag_name ---
my $tag2_name = Git::Libgit2::FFI::git_tag_name($tag2_obj);
is( $tag2_name, 'v2.0-annotated', 'tag_name returns correct name' );

# --- git_tag_target ---
my $target_obj;
check_rc Git::Libgit2::FFI::git_tag_target( \$target_obj, $tag2_obj );
ok( $target_obj, 'tag_target returned an object' );
my $target_id = Git::Libgit2::FFI::git_object_id($target_obj);
is( oid_to_hex($target_id), $c2_hex, 'tag target matches c2' );
Git::Libgit2::FFI::git_object_free($target_obj);

# --- git_tag_message ---
my $tag_msg = Git::Libgit2::FFI::git_tag_message($tag2_obj);
is( $tag_msg, "This is an annotated tag message\n", 'tag_message returns correct message' );

Git::Libgit2::FFI::git_tag_free($tag2_obj);

# --- git_tag_create (high-level annotated create; oid out-param is a
#     caller-allocated buffer, so the binding must use 'opaque' not
#     'opaque*' — this is the path Git::Native's tag_create takes) ---
my $c1_obj;
check_rc Git::Libgit2::FFI::git_object_lookup( \$c1_obj, $repo, $c1_buf, -2 );  # GIT_OBJECT_ANY
my $tag3_buf_raw = "\0" x 20;
my ($tag3_buf) = scalar_to_buffer($tag3_buf_raw);
check_rc Git::Libgit2::FFI::git_tag_create(
  $tag3_buf, $repo, 'v3.0-annotated', $c1_obj, $sig, "high-level annotated\n", 0,
);
like( oid_to_hex($tag3_buf), qr/\A[0-9a-f]{40}\z/, 'annotated tag created via git_tag_create' );
my $tag3_obj;
check_rc Git::Libgit2::FFI::git_tag_lookup( \$tag3_obj, $repo, $tag3_buf );
is( Git::Libgit2::FFI::git_tag_name($tag3_obj), 'v3.0-annotated', 'git_tag_create tag name round-trips' );
Git::Libgit2::FFI::git_tag_free($tag3_obj);
Git::Libgit2::FFI::git_object_free($c1_obj);

# --- git_tag_list ---
my $strarray_buf = "\0" x 4096;
my ($strarray_ptr) = scalar_to_buffer($strarray_buf);
check_rc Git::Libgit2::FFI::git_tag_list( $strarray_ptr, $repo );
my $tag_count = unpack( 'L', substr($strarray_buf, 0, 4) );
ok( $tag_count >= 1, 'tag_list returned at least 1 tag' );
Git::Libgit2::FFI::git_strarray_free($strarray_ptr);

# Cleanup
Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
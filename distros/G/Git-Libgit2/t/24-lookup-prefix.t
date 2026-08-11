use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw(
  init_lib shutdown_lib check_rc oid_to_hex
  GIT_OBJECT_COMMIT GIT_OID_MINPREFIXLEN GIT_EAMBIGUOUS
);
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );
# Sterile CI containers default to master; pin main so refs/heads/main exists.
check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );

# Build a standalone commit (no parents) on a unique ref. Returns the raw
# 20-byte OID buffer of the new commit and its hex form.
my $ref_seq = 0;
sub make_commit {
  my ( $label ) = @_;
  my $refname = "refs/heads/branch" . ( $ref_seq++ );
  my $content = "$label\n";
  my ( $content_ptr ) = scalar_to_buffer($content);

  my $blob_buf = "\0" x 20;
  my ($blob_ptr) = scalar_to_buffer($blob_buf);
  check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob_ptr, $repo, $content_ptr, length($content) );

  my $tb;
  check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $repo, undef );
  check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e, $tb, 'file.txt', $blob_ptr, 0100644 );
  my $tree_buf = "\0" x 20;
  my ($tree_ptr) = scalar_to_buffer($tree_buf);
  check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_ptr, $tb );
  Git::Libgit2::FFI::git_treebuilder_free($tb);

  my $tree;
  check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree, $repo, $tree_ptr );
  my $sig;
  check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Author', 'author@example.invalid', 1715000000, 0 );

  my $commit_buf = "\0" x 20;
  my ($commit_ptr) = scalar_to_buffer($commit_buf);
  check_rc Git::Libgit2::FFI::git_commit_create(
    $commit_ptr, $repo, $refname, $sig, $sig,
    'UTF-8', $label, $tree, 0, undef,
  );
  my $hex = oid_to_hex($commit_ptr);
  Git::Libgit2::FFI::git_tree_free($tree);
  Git::Libgit2::FFI::git_signature_free($sig);
  return ( $commit_buf, $hex );
}

# ---------------------------------------------------------------------------
# 1. Full-length prefix lookup of a single commit succeeds.
# ---------------------------------------------------------------------------

my ( $c1_buf, $c1_hex ) = make_commit('initial commit');
# Use an 8-hex-character prefix: well above MINPREFIXLEN, unambiguous for one
# object. $len is in HEX CHARACTERS (nibbles), not bytes (Hausregel 11).
{
  my ($full_ptr) = scalar_to_buffer($c1_buf);
  my $obj;
  check_rc Git::Libgit2::FFI::git_object_lookup_prefix(
    \$obj, $repo, $full_ptr, 8, GIT_OBJECT_COMMIT
  );
  ok( $obj, 'lookup_prefix with 8-nibble prefix returned an object handle' );
  is( Git::Libgit2::FFI::git_object_type($obj), GIT_OBJECT_COMMIT,
    'prefix-resolved object is a COMMIT' );
  is( oid_to_hex( Git::Libgit2::FFI::git_object_id($obj) ), $c1_hex,
    'prefix-resolved OID matches the commit' );
  Git::Libgit2::FFI::git_object_free($obj);
}

# ---------------------------------------------------------------------------
# 2. Ambiguous prefix -> GIT_EAMBIGUOUS. With len=0 the "prefix" is empty and
#    matches every object in the repo, so a repository holding >=2 objects is
#    always ambiguous. This is the deterministic guaranteed-ambiguous case
#    (Hausregel 7: the test exercises the EAMBIGUOUS code path for real — no
#    birthday-paradox luck involved). The first commit already exists; add a
#    second on its own ref and query with len=0.
# ---------------------------------------------------------------------------

my ( $c2_buf, $c2_hex ) = make_commit('second commit');
{
  my ($p) = scalar_to_buffer($c1_buf);
  my $rc = Git::Libgit2::FFI::git_object_lookup_prefix(
    \my $amb_obj, $repo, $p, 0, GIT_OBJECT_COMMIT
  );
  is( $rc, GIT_EAMBIGUOUS,
    "lookup_prefix with len=0 over a repo with 2 objects returns GIT_EAMBIGUOUS (rc=$rc)" );
  note "strategy: len=0 (empty prefix) over 2 objects -> always EAMBIGUOUS; deterministic";
}

# ---------------------------------------------------------------------------
# 3. Non-existent prefix -> error (not 0, not EAMBIGUOUS). Flip one nibble of
#    the full OID and query with full length: object not found.
# ---------------------------------------------------------------------------

{
  my $bad_hex = $c1_hex;
  my $last = substr($bad_hex, -1, 1);
  my $replacement = ( $last eq '0' ) ? '1' : '0';
  substr( $bad_hex, -1, 1 ) = $replacement;
  my $bad_oid = Git::Libgit2::oid_from_hex($bad_hex);
  my ($bad_ptr) = scalar_to_buffer($bad_oid);
  my $rc = Git::Libgit2::FFI::git_object_lookup_prefix(
    \my $obj, $repo, $bad_ptr, length($bad_hex), GIT_OBJECT_COMMIT
  );
  ok( $rc < 0,
    "lookup_prefix for a non-existent OID returns a negative error (rc=$rc)" );
}

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
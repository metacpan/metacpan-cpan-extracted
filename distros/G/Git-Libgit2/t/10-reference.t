use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw(
  GIT_EMODIFIED init_lib shutdown_lib check_rc oid_to_hex
);
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );
# Pin HEAD to 'main' (sterile CI containers default to 'master' otherwise).
check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );

# --- build a commit so we have something to point refs at ---
my $blob_content = "hello ref\n";
my $blob_oid_buf = "\0" x 20;
my ($blob_oid_ptr) = scalar_to_buffer($blob_oid_buf);
my ($content_ptr) = scalar_to_buffer($blob_content);
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer(
  $blob_oid_ptr, $repo, $content_ptr, length($blob_content),
);

my $tb;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert(
  \my $entry, $tb, 'hello.txt', $blob_oid_ptr, 0100644,
);
my $tree_oid_buf = "\0" x 20;
my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_oid_ptr, $tb );
Git::Libgit2::FFI::git_treebuilder_free($tb);

my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Test', 'test@example.invalid', 1715000000, 0 );

my $tree2;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree2, $repo, $tree_oid_ptr );
my $commit_oid_buf = "\0" x 20;
my ($commit_oid_ptr) = scalar_to_buffer($commit_oid_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $commit_oid_ptr, $repo, 'HEAD', $sig, $sig,
  'UTF-8', 'initial', $tree2, 0, undef,
);
my $commit_hex = oid_to_hex($commit_oid_ptr);

# --- git_reference_name_is_valid ---
my $valid_out = 0;
check_rc Git::Libgit2::FFI::git_reference_name_is_valid( \$valid_out, 'refs/heads/main' );
ok( $valid_out, 'refs/heads/main is a valid ref name' );

my $invalid_out = 0;
check_rc Git::Libgit2::FFI::git_reference_name_is_valid( \$invalid_out, 'not-a-valid-ref-n amph' );
ok( !$invalid_out, 'invalid ref name rejected' );

# --- git_reference_lookup ---
my $head;
check_rc Git::Libgit2::FFI::git_reference_lookup( \$head, $repo, 'refs/heads/main' );
ok( $head, 'reference_lookup found main' );
is( oid_to_hex( Git::Libgit2::FFI::git_reference_target($head) ),
    $commit_hex, 'main target matches commit' );
is( Git::Libgit2::FFI::git_reference_name($head), 'refs/heads/main', 'ref name matches' );
like( Git::Libgit2::FFI::git_reference_type($head), qr/\A[0-9]+\z/, 'type is a positive int' );
Git::Libgit2::FFI::git_reference_free($head);

# --- git_reference_create ---
my $created_ref;
check_rc Git::Libgit2::FFI::git_reference_create(
  \$created_ref, $repo, 'refs/heads/test-branch', $commit_oid_ptr, 0, 'test commit',
);
is(
  oid_to_hex( Git::Libgit2::FFI::git_reference_target($created_ref) ),
  $commit_hex,
  'reference_create returns a reference pointing at the requested OID',
);
Git::Libgit2::FFI::git_reference_free($created_ref);

# --- git_reference_create_matching ---
my $matched_ref;
check_rc Git::Libgit2::FFI::git_reference_create_matching(
  \$matched_ref, $repo, 'refs/heads/test-branch', $blob_oid_ptr, 1,
  $commit_oid_ptr, 'matching update',
);
is(
  oid_to_hex( Git::Libgit2::FFI::git_reference_target($matched_ref) ),
  oid_to_hex($blob_oid_ptr),
  'reference_create_matching updates when the expected OID matches',
);
Git::Libgit2::FFI::git_reference_free($matched_ref);

my $mismatched_ref;
my $mismatch_rc = Git::Libgit2::FFI::git_reference_create_matching(
  \$mismatched_ref, $repo, 'refs/heads/test-branch', $commit_oid_ptr, 1,
  $commit_oid_ptr, 'stale matching update',
);
is( $mismatch_rc, GIT_EMODIFIED, 'stale expected OID returns GIT_EMODIFIED' );
ok( !$mismatched_ref, 'failed matching update does not return a reference handle' );

my $matched_lookup;
check_rc Git::Libgit2::FFI::git_reference_lookup(
  \$matched_lookup, $repo, 'refs/heads/test-branch',
);
is(
  oid_to_hex( Git::Libgit2::FFI::git_reference_target($matched_lookup) ),
  oid_to_hex($blob_oid_ptr),
  'failed matching update leaves the reference unchanged',
);
Git::Libgit2::FFI::git_reference_free($matched_lookup);

# --- git_reference_delete ---
my $branch_ref;
check_rc Git::Libgit2::FFI::git_reference_lookup( \$branch_ref, $repo, 'refs/heads/test-branch' );
check_rc Git::Libgit2::FFI::git_reference_delete($branch_ref);
Git::Libgit2::FFI::git_reference_free($branch_ref);

my $lookup_after_delete;
my $rc = Git::Libgit2::FFI::git_reference_lookup( \$lookup_after_delete, $repo, 'refs/heads/test-branch' );
ok( $rc != 0, 'reference_delete removes the ref' );

# --- iterator ---
my $iter;
check_rc Git::Libgit2::FFI::git_reference_iterator_new( \$iter, $repo );
my $count = 0;
while (1) {
  my $ref;
  my $r = Git::Libgit2::FFI::git_reference_next( \$ref, $iter );
  last if $r != 0;
  Git::Libgit2::FFI::git_reference_free($ref);
  $count++;
}
ok( $count > 0, "iterator returned $count refs" );
Git::Libgit2::FFI::git_reference_iterator_free($iter);

# --- glob iterator ---
my $glob_iter;
check_rc Git::Libgit2::FFI::git_reference_iterator_glob_new( \$glob_iter, $repo, 'refs/heads/*' );
my $glob_count = 0;
while (1) {
  my $name;
  my $r = Git::Libgit2::FFI::git_reference_next_name( \$name, $glob_iter );
  last if $r != 0;
  ok( defined $name, "glob iterator returned ref name: $name" );
  $glob_count++;
}
ok( $glob_count > 0, "glob iterator returned $glob_count names" );
Git::Libgit2::FFI::git_reference_iterator_free($glob_iter);

Git::Libgit2::FFI::git_tree_free($tree2);
Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;

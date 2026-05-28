use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc oid_from_hex oid_to_hex );
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
ok( Git::Libgit2::FFI::git_repository_head_unborn($repo), 'HEAD unborn before first commit' );

# --- write a blob ---
my $blob_content = "hello libgit2\n";
my $blob_oid_buf = "\0" x 20;
my ($blob_oid_ptr) = scalar_to_buffer($blob_oid_buf);
my ($content_ptr)  = scalar_to_buffer($blob_content);
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer(
  $blob_oid_ptr, $repo, $content_ptr, length($blob_content),
);
my $blob_hex = oid_to_hex($blob_oid_ptr);
like( $blob_hex, qr/\A[0-9a-f]{40}\z/, "blob OID looks like a SHA-1: $blob_hex" );

# --- read the blob back ---
my $blob_obj;
check_rc Git::Libgit2::FFI::git_blob_lookup( \$blob_obj, $repo, $blob_oid_ptr );
ok( $blob_obj, 'git_blob_lookup found the blob' );
is( Git::Libgit2::FFI::git_blob_rawsize($blob_obj), length($blob_content), 'rawsize matches' );
Git::Libgit2::FFI::git_blob_free($blob_obj);

# --- OID round-trip via hex ---
my $raw_again = oid_from_hex($blob_hex);
my ($raw_again_ptr) = scalar_to_buffer($raw_again);
is( oid_to_hex($raw_again_ptr), $blob_hex, 'hex -> raw -> hex round-trip stable' );

# --- build a tree containing the blob ---
my $tb;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert(
  \my $entry, $tb, 'hello.txt', $blob_oid_ptr, 0100644,
);

my $tree_oid_buf = "\0" x 20;
my ($tree_oid_ptr) = scalar_to_buffer($tree_oid_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $tree_oid_ptr, $tb );
Git::Libgit2::FFI::git_treebuilder_free($tb);
my $tree_hex = oid_to_hex($tree_oid_ptr);
like( $tree_hex, qr/\A[0-9a-f]{40}\z/, "tree OID: $tree_hex" );

# --- look up the tree and walk it ---
my $tree;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree, $repo, $tree_oid_ptr );
is( Git::Libgit2::FFI::git_tree_entrycount($tree), 1, 'tree has one entry' );
my $te = Git::Libgit2::FFI::git_tree_entry_byname( $tree, 'hello.txt' );
ok( $te, 'tree_entry_byname found hello.txt' );
is( Git::Libgit2::FFI::git_tree_entry_name($te), 'hello.txt', 'entry name matches' );
Git::Libgit2::FFI::git_tree_free($tree);

# --- create a commit pointing at this tree ---
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Test', 'test@example.invalid', 1715000000, 0 );

# Re-look up the tree for the commit (commit_create takes a git_tree*).
my $tree2;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree2, $repo, $tree_oid_ptr );

my $commit_oid_buf = "\0" x 20;
my ($commit_oid_ptr) = scalar_to_buffer($commit_oid_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $commit_oid_ptr, $repo,
  'HEAD',           # update_ref
  $sig, $sig,
  'UTF-8',          # message_encoding
  'initial',        # message
  $tree2,
  0,                # parent_count
  undef,            # parents
);
my $commit_hex = oid_to_hex($commit_oid_ptr);
like( $commit_hex, qr/\A[0-9a-f]{40}\z/, "commit OID: $commit_hex" );

# --- verify ref/HEAD now points at the commit ---
my $head;
check_rc Git::Libgit2::FFI::git_reference_lookup( \$head, $repo, 'refs/heads/main' );
ok( $head, 'refs/heads/main exists after commit' );
is( oid_to_hex( Git::Libgit2::FFI::git_reference_target($head) ),
    $commit_hex,
    'main points at our commit' );
Git::Libgit2::FFI::git_reference_free($head);

# --- commit accessors (Group A) ---
my $commit_obj;
check_rc Git::Libgit2::FFI::git_commit_lookup( \$commit_obj, $repo, $commit_oid_ptr );
is( oid_to_hex( Git::Libgit2::FFI::git_commit_id($commit_obj) ),
    $commit_hex, 'git_commit_id matches the created OID' );
is( Git::Libgit2::FFI::git_commit_time($commit_obj), 1715000000, 'git_commit_time matches signature time' );
is( Git::Libgit2::FFI::git_commit_time_offset($commit_obj), 0, 'git_commit_time_offset is 0' );
is( Git::Libgit2::FFI::git_commit_summary($commit_obj), 'initial', 'git_commit_summary is the message' );
Git::Libgit2::FFI::git_commit_free($commit_obj);

# --- repository HEAD now born + attached (Group A) ---
ok( ! Git::Libgit2::FFI::git_repository_head_unborn($repo),   'HEAD no longer unborn after commit' );
ok( ! Git::Libgit2::FFI::git_repository_head_detached($repo), 'HEAD is not detached' );
my $head_ref;
check_rc Git::Libgit2::FFI::git_repository_head( \$head_ref, $repo );
is( Git::Libgit2::FFI::git_reference_name($head_ref), 'refs/heads/main', 'git_repository_head resolves to main' );

# --- reference predicates / shorthand (Group A) ---
is( Git::Libgit2::FFI::git_reference_shorthand($head_ref), 'main', 'shorthand strips refs/heads/' );
ok(   Git::Libgit2::FFI::git_reference_is_branch($head_ref), 'is_branch true for refs/heads/main' );
ok( ! Git::Libgit2::FFI::git_reference_is_remote($head_ref), 'is_remote false' );
ok( ! Git::Libgit2::FFI::git_reference_is_tag($head_ref),    'is_tag false' );
Git::Libgit2::FFI::git_reference_free($head_ref);

# --- symbolic HEAD: target + resolve (Group A) ---
my $head_sym;
check_rc Git::Libgit2::FFI::git_reference_lookup( \$head_sym, $repo, 'HEAD' );
is( Git::Libgit2::FFI::git_reference_symbolic_target($head_sym),
    'refs/heads/main', 'HEAD symbolic target is refs/heads/main' );
my $resolved;
check_rc Git::Libgit2::FFI::git_reference_resolve( \$resolved, $head_sym );
is( Git::Libgit2::FFI::git_reference_name($resolved), 'refs/heads/main', 'resolve follows HEAD to main' );
Git::Libgit2::FFI::git_reference_free($resolved);
Git::Libgit2::FFI::git_reference_free($head_sym);

# --- symbolic_create (Group A) ---
my $sym_ref;
check_rc Git::Libgit2::FFI::git_reference_symbolic_create(
  \$sym_ref, $repo, 'refs/heads/alias', 'refs/heads/main', 0, 'create alias'
);
is( Git::Libgit2::FFI::git_reference_symbolic_target($sym_ref),
    'refs/heads/main', 'symbolic_create set the target' );
Git::Libgit2::FFI::git_reference_free($sym_ref);

Git::Libgit2::FFI::git_tree_free($tree2);
Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;

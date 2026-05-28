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

# Pre-allocate all OID buffers at outer scope so scalar_to_buffer
# pointers stay valid for the whole test (avoids Perl buffer relocation).
my $b1_buf = "\0" x 20;
my $b2_buf = "\0" x 20;
my $t1_buf = "\0" x 20;
my $t2_buf = "\0" x 20;
my $c1_buf = "\0" x 20;
my $c2_buf = "\0" x 20;

# --- blob v1 ---
my ($b1_ptr) = scalar_to_buffer($b1_buf);
my ($c1_content_ptr) = scalar_to_buffer("v1\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b1_ptr, $repo, $c1_content_ptr, 3 );

# --- blob v2 ---
my ($b2_ptr) = scalar_to_buffer($b2_buf);
my ($c2_content_ptr) = scalar_to_buffer("v2\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $b2_ptr, $repo, $c2_content_ptr, 3 );

# --- tree 1 (a.txt = v1) ---
my $tb1;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb1, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e1, $tb1, 'a.txt', $b1_ptr, 0100644 );
my ($t1_ptr) = scalar_to_buffer($t1_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t1_ptr, $tb1 );
Git::Libgit2::FFI::git_treebuilder_free($tb1);

# --- tree 2 (a.txt = v2) ---
my $tb2;
check_rc Git::Libgit2::FFI::git_treebuilder_new( \$tb2, $repo, undef );
check_rc Git::Libgit2::FFI::git_treebuilder_insert( \my $e2, $tb2, 'a.txt', $b2_ptr, 0100644 );
my ($t2_ptr) = scalar_to_buffer($t2_buf);
check_rc Git::Libgit2::FFI::git_treebuilder_write( $t2_ptr, $tb2 );
Git::Libgit2::FFI::git_treebuilder_free($tb2);

# --- look up trees for diff ---
my $tree1;
my $tree2;
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree1, $repo, $t1_ptr );
check_rc Git::Libgit2::FFI::git_tree_lookup( \$tree2, $repo, $t2_ptr );

# --- git_diff_options_init ---
my $opts_buf = "\0" x 256;
my ($opts_ptr) = scalar_to_buffer($opts_buf);
check_rc Git::Libgit2::FFI::git_diff_options_init( $opts_ptr, 1 );

# --- git_diff_tree_to_tree ---
my $diff;
check_rc Git::Libgit2::FFI::git_diff_tree_to_tree( \$diff, $repo, $tree1, $tree2, $opts_ptr );
ok( $diff, 'git_diff_tree_to_tree returned a diff handle' );

my $nd = Git::Libgit2::FFI::git_diff_num_deltas($diff);
ok( $nd >= 1, "diff has $nd delta(s)" );

my $delta = Git::Libgit2::FFI::git_diff_get_delta( $diff, 0 );
ok( $delta, 'git_diff_get_delta(0) returned something' );

Git::Libgit2::FFI::git_diff_free($diff);

# --- create commits on separate branches to confirm diff is real ---
my $sig;
check_rc Git::Libgit2::FFI::git_signature_new( \$sig, 'Test', 'test@example.invalid', 1715000000, 0 );

my ($c1_ptr) = scalar_to_buffer($c1_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c1_ptr, $repo, 'refs/heads/b1', $sig, $sig,
  'UTF-8', 'first commit', $tree1, 0, undef,
);

my ($c2_ptr) = scalar_to_buffer($c2_buf);
check_rc Git::Libgit2::FFI::git_commit_create(
  $c2_ptr, $repo, 'refs/heads/b2', $sig, $sig,
  'UTF-8', 'second commit', $tree2, 0, undef,
);

ok( 1, 'commits created successfully on independent branches' );

Git::Libgit2::FFI::git_signature_free($sig);
Git::Libgit2::FFI::git_tree_free($tree1);
Git::Libgit2::FFI::git_tree_free($tree2);
Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
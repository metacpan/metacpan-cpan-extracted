use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Signature;

my ( $repo, $tmp ) = TestRepo::new_repo();   # keep $tmp alive — tempdir is auto-removed when its refcount hits 0
ok( $repo,        'init returned a repository' );
like( $repo->workdir, qr{/$},      'workdir ends with slash' );
ok( ! $repo->is_bare,              'non-bare by default' );

# blob
my $blob_oid = $repo->blob_create_frombuffer("hello native git\n");
like( "$blob_oid", qr/\A[0-9a-f]{40}\z/, "blob OID: $blob_oid" );

my $blob = $repo->blob($blob_oid);
is( $blob->size, length("hello native git\n"), 'blob size matches' );
is( $blob->content, "hello native git\n",      'blob content round-trips' );
is( "@{[ $blob->oid ]}", "$blob_oid",          'blob oid identity' );

# tree
my $tb = $repo->tree_builder;
$tb->insert(name => 'hi.txt', oid => $blob_oid, mode => 0100644);
my $tree_oid = $tb->write;
like( "$tree_oid", qr/\A[0-9a-f]{40}\z/, "tree OID: $tree_oid" );

my $tree = $repo->tree($tree_oid);
is( $tree->entrycount, 1, 'tree has one entry' );
my $entries = $tree->entries;
is( $entries->[0]{name}, 'hi.txt', 'entry name' );
is( "$entries->[0]{oid}", "$blob_oid", 'entry oid matches blob' );

# commit (no parents)
my $sig = Git::Native::Signature->new(
  name   => 'Test',
  email  => 'test@example.invalid',
  when   => 1715000000,
  offset => 0,
);
my $commit_oid = $repo->commit_create(
  update_ref => 'HEAD',
  tree       => $tree_oid,
  parents    => [],
  message    => 'initial',
  author     => $sig,
  committer  => $sig,
);
like( "$commit_oid", qr/\A[0-9a-f]{40}\z/, "commit OID: $commit_oid" );

# read commit back
my $commit = $repo->commit($commit_oid);
is( $commit->message, 'initial',          'commit message' );
is( "@{[ $commit->tree_oid ]}", "$tree_oid", 'commit -> tree oid' );
is( $commit->parent_count, 0,             'no parents' );

# follow-up commit with parent
my $blob_oid_2 = $repo->blob_create_frombuffer("v2\n");
my $tb2 = $repo->tree_builder;
$tb2->insert(name => 'hi.txt', oid => $blob_oid_2, mode => 0100644);
my $tree_oid_2 = $tb2->write;
my $commit_oid_2 = $repo->commit_create(
  update_ref => 'HEAD',
  tree       => $tree_oid_2,
  parents    => [$commit_oid],
  message    => 'second',
  author     => $sig,
  committer  => $sig,
);
my $commit2 = $repo->commit($commit_oid_2);
is( $commit2->parent_count, 1, 'second commit has 1 parent' );
is( "@{[ $commit2->parent_oids->[0] ]}", "$commit_oid", 'parent oid matches first commit' );

# references
ok( $repo->reference_exists('refs/heads/main'), 'refs/heads/main exists' );
my $main = $repo->reference('refs/heads/main');
is( "@{[ $main->target ]}", "$commit_oid_2", 'main now at second commit' );

my $names = $repo->reference_names;
ok( ( grep { $_ eq 'refs/heads/main' } @$names ), 'iterator lists main' );

# custom ref
$repo->reference_create('refs/karr/test', $commit_oid_2);
ok( $repo->reference_exists('refs/karr/test'), 'created refs/karr/test' );
$repo->reference_delete('refs/karr/test');
ok( ! $repo->reference_exists('refs/karr/test'), 'deleted refs/karr/test' );

done_testing;

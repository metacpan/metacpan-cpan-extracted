use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Signature;

# Repository->object($oid) looks up an object of unknown kind and returns the
# matching typed wrapper. Documented in the class layout but previously not
# implemented and never tested.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob_oid = $repo->blob_create_frombuffer("payload\n");
my $tb       = $repo->tree_builder;
$tb->insert( name => 'f', oid => $blob_oid, mode => 0100644 );
my $tree_oid   = $tb->write;
my $commit_oid = $repo->commit_create(
  tree => $tree_oid, parents => [], message => 'c',
);
my $tag_oid = $repo->tag_create(
  'v1.0.0', $commit_oid,
  message => "rel\n",
  tagger  => Git::Native::Signature->new( name => 'T', email => 't@e' ),
);

# Each OID resolves to the right wrapper, and the wrapper actually works.
my $blob = $repo->object($blob_oid);
isa_ok $blob, ['Git::Native::Blob'], 'blob oid -> Blob';
is $blob->content, "payload\n", 'wrapped blob reads its content';

my $tree = $repo->object($tree_oid);
isa_ok $tree, ['Git::Native::Tree'], 'tree oid -> Tree';
is $tree->entrycount, 1, 'wrapped tree has the entry';

my $commit = $repo->object($commit_oid);
isa_ok $commit, ['Git::Native::Commit'], 'commit oid -> Commit';
is $commit->message, 'c', 'wrapped commit reads its message';

my $tag = $repo->object($tag_oid);
isa_ok $tag, ['Git::Native::Tag'], 'annotated tag oid -> Tag';
is $tag->name, 'v1.0.0', 'wrapped tag reads its name';

# Accepts a hex string too, not just an Oid object.
isa_ok $repo->object( "$blob_oid" ), ['Git::Native::Blob'],
  'object() accepts a hex string';

# Unknown oid -> the typed error path (covered broadly in t/46, asserted here
# for the object() entry point specifically).
my $err = dies { $repo->object( '0' x 40 ) };
isa_ok $err, ['Git::Native::Error'], 'object() on a missing oid throws';

done_testing;

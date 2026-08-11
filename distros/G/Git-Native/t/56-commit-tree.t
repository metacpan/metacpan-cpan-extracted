use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# Git::Native::Commit->tree and the lazy `oid` builder had no caller in the
# suite: t/38 reads message/summary/time, t/48 counts parents. This file pins
# the object-graph side - tree vs tree_oid agreeing, the 0-parent root shape,
# and the memory-ownership rule that a Tree obtained from a Commit stays valid
# after that Commit is gone (it holds the Repository, not the Commit).

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("payload\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'f', oid => $blob, mode => 0100644 );
my $tree_oid = $tb->write;

my $root = $repo->commit_create(
  tree => $tree_oid, parents => [], message => 'root',
);
my $child = $repo->commit_create(
  tree => $tree_oid, parents => [$root], message => 'child',
);

subtest 'oid / tree / tree_oid agree' => sub {
  my $commit = $repo->commit($child);

  is $commit->oid->hex, $child->hex, 'commit->oid is the OID it was looked up by';
  is $commit->oid->hex, $child->hex, 'commit->oid is stable across calls (lazy build)';

  is $commit->tree_oid->hex, $tree_oid->hex, 'tree_oid is the tree we committed';

  my $tree = $commit->tree;
  isa_ok $tree, ['Git::Native::Tree'], 'tree returns a Tree wrapper';
  is $tree->oid->hex, $tree_oid->hex, 'the Tree carries the same OID as tree_oid';
  is [ map { $_->{name} } @{ $tree->entries } ], ['f'],
    'the Tree is usable - it lists the committed entry';
};

subtest 'a root commit has no parents' => sub {
  my $commit = $repo->commit($root);
  is $commit->parent_count, 0, 'parent_count is 0 for a root commit';
  is $commit->parent_oids, [], 'parent_oids is an empty arrayref, not undef';
};

subtest 'a child commit records its parent' => sub {
  my $commit = $repo->commit($child);
  is $commit->parent_count, 1, 'parent_count is 1';
  is [ map { $_->hex } @{ $commit->parent_oids } ], [ $root->hex ],
    'parent_oids lists the parent OID';
};

subtest 'a Tree outlives the Commit it came from' => sub {
  # Memory ownership: Commit->tree passes _owner => the Repository, so the
  # Tree does not depend on the Commit staying alive. If that ever changed to
  # _owner => $commit-and-nothing-else, freeing the commit here would leave a
  # dangling handle and this read would be a use-after-free.
  my $tree;
  {
    my $commit = $repo->commit($child);
    $tree = $commit->tree;
  }   # $commit demolished, git_commit_free called

  is $tree->entrycount, 1, 'the Tree still reads after its Commit was freed';
  is $tree->entry_by_name('f')->{oid}->hex, $blob->hex,
    'and its entries are still intact';
};

subtest 'commit lookup of a non-commit OID fails typed' => sub {
  # The tree OID is a real object, just the wrong kind - libgit2 must reject
  # it rather than hand back a Commit wrapper over a git_tree*.
  my $err = dies { $repo->commit($tree_oid) };
  isa_ok $err, ['Git::Native::Error'], 'commit() on a tree OID throws';
  ok $err->code < 0, 'with a negative libgit2 code';
};

done_testing;

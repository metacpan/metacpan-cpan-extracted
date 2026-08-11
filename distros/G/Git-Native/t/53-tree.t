use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Libgit2 qw( GIT_OBJECT_BLOB GIT_OBJECT_TREE );

# Git::Native::Tree had the weakest branch coverage in the distribution:
# entry_by_name was never called at all, `entries` was only ever run against a
# single-entry tree, and the lazy `oid` builder was dead code as far as the
# suite was concerned. This file pins the shapes that actually differ:
# empty tree, several entries, a nested subtree, and a name that is not there.

my ( $repo, $tmp ) = TestRepo::new_repo();

subtest 'empty tree' => sub {
  my $oid = $repo->tree_builder->write;

  # git's empty tree has a fixed OID - if this ever changes we are not talking
  # to git object storage any more.
  is "$oid", '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
    'empty tree hashes to the well-known empty-tree OID';

  my $tree = $repo->tree($oid);
  is $tree->entrycount, 0, 'entrycount is 0';
  is $tree->entries, [], 'entries on an empty tree is an empty arrayref, not undef';
  is $tree->entry_by_name('anything'), undef,
    'entry_by_name on an empty tree is undef';
};

subtest 'entries: several blobs plus a subtree' => sub {
  my $a   = $repo->blob_create_frombuffer("A\n");
  my $b   = $repo->blob_create_frombuffer("B\n");

  my $sub_tb = $repo->tree_builder;
  $sub_tb->insert( name => 'inner', oid => $b, mode => 0100644 );
  my $sub = $sub_tb->write;

  # Insert deliberately out of order: git stores tree entries sorted by name,
  # and `entries` walks by index, so the result must come back sorted rather
  # than in insertion order.
  my $tb = $repo->tree_builder;
  $tb->insert( name => 'sub',   oid => $sub, mode => 040000 );
  $tb->insert( name => 'b.txt', oid => $b,   mode => 0100644 );
  $tb->insert( name => 'a.txt', oid => $a,   mode => 0100644 );
  $tb->insert( name => 'run.sh', oid => $a,  mode => 0100755 );
  my $top = $tb->write;

  my $tree = $repo->tree($top);
  is $tree->entrycount, 4, 'entrycount counts every entry';

  my $entries = $tree->entries;
  is [ map { $_->{name} } @$entries ],
     [ qw( a.txt b.txt run.sh sub ) ],
     'entries come back in git tree order, not insertion order';

  # Each entry carries name / oid / mode / type - the mode and type are what
  # tell a caller a blob from a subtree, so pin both.
  my ($a_entry) = grep { $_->{name} eq 'a.txt' } @$entries;
  is $a_entry->{oid}->hex, $a->hex, 'blob entry points at the blob OID';
  is $a_entry->{mode}, 0100644, 'regular file mode';
  is $a_entry->{type}, GIT_OBJECT_BLOB, 'regular file type is blob';

  my ($x_entry) = grep { $_->{name} eq 'run.sh' } @$entries;
  is $x_entry->{mode}, 0100755, 'executable bit survives the round trip';

  my ($sub_entry) = grep { $_->{name} eq 'sub' } @$entries;
  is $sub_entry->{oid}->hex, $sub->hex, 'subtree entry points at the subtree OID';
  is $sub_entry->{mode}, 040000, 'subtree mode';
  is $sub_entry->{type}, GIT_OBJECT_TREE, 'subtree type is tree';

  # The subtree really is a tree we can descend into.
  my $inner = $repo->tree( $sub_entry->{oid} );
  is [ map { $_->{name} } @{ $inner->entries } ], ['inner'],
    'the subtree OID resolves to a tree with its own entry';

  # ---- entry_by_name ----
  my $by_name = $tree->entry_by_name('b.txt');
  is $by_name->{oid}->hex, $b->hex, 'entry_by_name finds an entry';
  is $by_name->{type}, GIT_OBJECT_BLOB, 'entry_by_name returns the same shape as entries';
  is $tree->entry_by_name('nope.txt'), undef,
    'entry_by_name returns undef for a name that is not in the tree';
  is $tree->entry_by_name('inner'), undef,
    'entry_by_name does not descend into subtrees';

  # ---- lazy oid ----
  is $tree->oid->hex, $top->hex, 'tree->oid is the OID it was looked up by';
  is $tree->oid->hex, $top->hex, 'tree->oid is stable across calls (lazy build)';
};

done_testing;

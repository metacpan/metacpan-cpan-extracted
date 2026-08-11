use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# TreeBuilder is used all over the suite, but only ever as
# insert(name, oid, mode) + write. `remove` had no caller at all, the
# hex-string form of `oid` and the `mode` default were never taken, and an
# invalid filemode - the one way insert can actually fail - was never checked
# to produce a typed error.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $a = $repo->blob_create_frombuffer("A\n");
my $b = $repo->blob_create_frombuffer("B\n");

subtest 'insert accepts a hex OID and defaults the mode to a regular file' => sub {
  my $tb = $repo->tree_builder;
  ref_is $tb->insert( name => 'plain', oid => $a->hex ), $tb,
    'insert takes a hex string and returns the builder for chaining';

  my $tree = $repo->tree( $tb->write );
  my $entry = $tree->entry_by_name('plain');
  is $entry->{oid}->hex, $a->hex, 'the hex OID landed in the tree';
  is $entry->{mode}, 0100644, 'mode defaults to 0100644 (regular file)';
};

subtest 'remove takes an entry back out' => sub {
  my $tb = $repo->tree_builder;
  $tb->insert( name => 'keep', oid => $a, mode => 0100644 );
  $tb->insert( name => 'drop', oid => $b, mode => 0100644 );

  ref_is $tb->remove('drop'), $tb, 'remove returns the builder for chaining';

  my $tree = $repo->tree( $tb->write );
  is [ map { $_->{name} } @{ $tree->entries } ], ['keep'],
    'the removed entry is not in the written tree';

  # Removing everything gets us back to the empty tree - proof that remove
  # mutates the builder rather than only filtering on write.
  $tb->remove('keep');
  is $tb->write . '', '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
    'removing the last entry writes the empty tree';
};

subtest 'removing a name that is not there fails typed' => sub {
  my $tb = $repo->tree_builder;
  $tb->insert( name => 'only', oid => $a, mode => 0100644 );
  my $err = dies { $tb->remove('missing') };
  isa_ok $err, ['Git::Native::Error'], 'remove of an absent entry throws';
  ok !$err->isa('Git::Libgit2::Error'), 'the low-level error does not leak';
  ok $err->code < 0, 'with a negative libgit2 code';

  # The builder is unharmed - a failed remove must not eat the other entries.
  my $tree = $repo->tree( $tb->write );
  is [ map { $_->{name} } @{ $tree->entries } ], ['only'],
    'the existing entry survived the failed remove';
};

subtest 'an invalid filemode is rejected' => sub {
  # git only accepts a fixed set of filemodes (0100644, 0100755, 0120000,
  # 040000, 0160000). Anything else must come back as a Git::Native::Error
  # rather than silently writing a corrupt tree.
  my $tb  = $repo->tree_builder;
  my $err = dies { $tb->insert( name => 'weird', oid => $a, mode => 0123456 ) };
  isa_ok $err, ['Git::Native::Error'], 'an invalid filemode throws';
  like $err->message, qr/filemode/i, 'the message names the filemode';

  # The builder is still usable and the rejected entry was not added.
  is $repo->tree( $tb->write )->entries, [],
    'a rejected insert leaves the builder empty rather than half-applied';
  $tb->insert( name => 'weird', oid => $a, mode => 0100644 );
  is [ map { $_->{name} } @{ $repo->tree( $tb->write )->entries } ], ['weird'],
    'the same name inserts fine once the mode is valid';
};

subtest 'the valid non-default filemodes round-trip' => sub {
  my $sub_oid = do {
    my $inner = $repo->tree_builder;
    $inner->insert( name => 'x', oid => $a, mode => 0100644 );
    $inner->write;
  };

  my $tb = $repo->tree_builder;
  $tb->insert( name => 'script', oid => $a,       mode => 0100755 );
  $tb->insert( name => 'link',   oid => $a,       mode => 0120000 );
  $tb->insert( name => 'dir',    oid => $sub_oid, mode => 040000 );

  my $tree = $repo->tree( $tb->write );
  my %mode = map { $_->{name} => $_->{mode} } @{ $tree->entries };
  is $mode{script}, 0100755, 'executable mode';
  is $mode{link},   0120000, 'symlink mode';
  is $mode{dir},    040000,  'subtree mode';
};

done_testing;

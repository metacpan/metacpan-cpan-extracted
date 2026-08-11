use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# Argument-shape coverage for Repository. Every OID-taking method documents
# "Oid or hex string", but commit_create's tree and parents had only ever been
# called with Oid objects; message_encoding always fell back to its default;
# branch_create's force flag never had a conflict to resolve; and
# reference_set_target's two Carp::croak guards - the ones that stop a
# non-atomic or nonsensical call before it reaches libgit2 - were unexecuted.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;

subtest 'commit_create takes hex strings for tree and parents' => sub {
  my $root = $repo->commit_create(
    tree => $tree->hex, parents => [], message => 'root from hex tree',
  );
  is $repo->commit($root)->tree_oid->hex, $tree->hex,
    'a hex tree OID is resolved';

  my $child = $repo->commit_create(
    tree    => $tree,
    parents => [ $root->hex ],
    message => 'child from hex parent',
  );
  is [ map { $_->hex } @{ $repo->commit($child)->parent_oids } ], [ $root->hex ],
    'a hex parent OID is resolved';

  # Mixed forms in one call - the conversion is per element, not per array.
  my $second_root = $repo->commit_create(
    tree => $tree, parents => [], message => 'second root',
  );
  my $merge = $repo->commit_create(
    tree    => $tree,
    parents => [ $child, $second_root->hex ],
    message => 'merge of an Oid and a hex parent',
  );
  is $repo->commit($merge)->parent_count, 2,
    'an Oid parent and a hex parent can be mixed in one commit';
};

subtest 'commit_create honours an explicit message_encoding' => sub {
  # The encoding is stored in the commit header; libgit2 hands the message
  # back unchanged either way, so assert on the raw object rather than the
  # message - otherwise the argument could be ignored and nothing would fail.
  my $rootless = $repo->commit_create(
    tree             => $tree,
    parents          => [],
    message          => 'encoded',
    message_encoding => 'ISO-8859-1',
  );
  isa_ok $repo->object($rootless), ['Git::Native::Commit'],
    'the commit was written on the zero-parent path';
  is $repo->commit($rootless)->message, 'encoded',
    'the message survives an explicit encoding';

  # And with a parent, which is the other branch of commit_create's
  # zero-parents / N-parents split.
  my $base = $repo->commit_create(
    tree => $tree, parents => [], message => 'base',
  );
  my $with_parent = $repo->commit_create(
    tree             => $tree,
    parents          => [$base],
    message          => 'encoded child',
    message_encoding => 'ISO-8859-1',
  );
  is $repo->commit($with_parent)->parent_count, 1,
    'an explicit encoding works on the N-parent path too';
};

subtest 'branch_create force resolves a name conflict' => sub {
  my $c1 = $repo->commit_create( tree => $tree, parents => [], message => 'b1' );
  my $c2 = $repo->commit_create( tree => $tree, parents => [$c1], message => 'b2' );

  $repo->branch_create( 'taken', $c1 );

  my $err = dies { $repo->branch_create( 'taken', $c2 ) };
  isa_ok $err, ['Git::Native::Error'], 'branch_create on a taken name throws';
  is $err->is_exists, 1, 'and it is the already-exists kind';
  is $repo->branch('taken')->target->hex, $c1->hex,
    'the refused create left the branch where it was';

  my $forced = $repo->branch_create( 'taken', $c2, force => 1 );
  is $forced->target->hex, $c2->hex, 'force => 1 moves the branch';
  is $repo->branch('taken')->target->hex, $c2->hex, 'and the move persisted';
};

subtest 'a symbolic ref under refs/heads has no branch target' => sub {
  # git_branch_lookup happily returns a symbolic ref living under
  # refs/heads/*; Branch->target must answer undef for it rather than
  # dereferencing a NULL git_oid*.
  my $c = $repo->commit_create( tree => $tree, parents => [], message => 'sym' );
  $repo->reference_create( 'refs/heads/real', $c, force => 1 );
  $repo->reference_symbolic_create( 'refs/heads/ptr', 'refs/heads/real' );

  my $branch = $repo->branch('ptr');
  is $branch->name, 'ptr', 'the symbolic ref is found as a branch';
  is $branch->target, undef, 'target is undef for a symbolic branch ref';

  # The underlying reference still resolves, so the information is reachable.
  is $repo->reference('refs/heads/ptr')->resolve->target->hex, $c->hex,
    'and the ref itself still resolves to the commit';
};

subtest 'reference_set_target refuses unsafe calls before touching libgit2' => sub {
  my $c1 = $repo->commit_create( tree => $tree, parents => [], message => 's1' );
  my $c2 = $repo->commit_create( tree => $tree, parents => [$c1], message => 's2' );
  $repo->reference_create( 'refs/heads/target', $c1, force => 1 );

  # expected_old is what makes this a compare-and-swap; without it the call
  # would be an unguarded overwrite, so it has to be refused rather than
  # quietly defaulting.
  my $missing = dies { $repo->reference_set_target( 'refs/heads/target', $c2 ) };
  like $missing, qr/reference_set_target requires expected_old/,
    'a call without expected_old croaks';
  ok !ref($missing), 'and it is a croak, not a libgit2 error';

  my $undef_old = dies {
    $repo->reference_set_target( 'refs/heads/target', $c2, expected_old => undef )
  };
  like $undef_old, qr/reference_set_target requires expected_old/,
    'an explicitly undef expected_old is refused too';

  is $repo->reference('refs/heads/target')->target->hex, $c1->hex,
    'neither refused call moved the reference';

  # A symbolic ref has no OID to compare against, so CAS is meaningless there.
  $repo->reference_symbolic_create(
    'refs/heads/sym-target', 'refs/heads/target', force => 1,
  );
  my $symbolic = dies {
    $repo->reference_set_target(
      'refs/heads/sym-target', $c2, expected_old => $c1,
    )
  };
  like $symbolic, qr/reference_set_target requires a direct reference/,
    'a symbolic ref is refused with a message naming the ref';
  like $symbolic, qr{refs/heads/sym-target}, 'and naming which ref it was';
};

subtest 'reference_create expected_old accepts a hex string' => sub {
  my $c1 = $repo->commit_create( tree => $tree, parents => [], message => 'x1' );
  my $c2 = $repo->commit_create( tree => $tree, parents => [$c1], message => 'x2' );

  $repo->reference_create( 'refs/cas/hex', $c1, expected_old => undef );

  my $updated = $repo->reference_create(
    'refs/cas/hex', $c2, expected_old => $c1->hex,
  );
  is $updated->target->hex, $c2->hex,
    'a hex expected_old is compared like an Oid one';

  my $stale = dies {
    $repo->reference_create( 'refs/cas/hex', $c1, expected_old => $c1->hex )
  };
  isa_ok $stale, ['Git::Native::Error'], 'a stale hex expected_old still throws';
  is $stale->is_not_matched, 1, 'and reports not-matched';
  is $repo->reference('refs/cas/hex')->target->hex, $c2->hex,
    'the stale update changed nothing';
};

done_testing;

use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Libgit2::FFI ();
use Git::Native;

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("cas\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'f', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $c1   = $repo->commit_create( tree => $tree, parents => [],    message => 'one' );
my $c2   = $repo->commit_create( tree => $tree, parents => [$c1], message => 'two' );
my $c3   = $repo->commit_create( tree => $tree, parents => [$c2], message => 'three' );

my $create_ref = 'refs/cas/create';
$repo->reference_create( $create_ref, $c1 );
my $has_create_matching =
  Git::Libgit2::FFI->can('git_reference_create_matching');

unless ($has_create_matching) {
  my $err = dies {
    $repo->reference_create( $create_ref, $c2, expected_old => $c1 );
  };
  like "$err", qr/Git::Libgit2 function git_reference_create_matching is not bound/,
    'missing create-matching binding has an actionable error';
}

subtest 'reference_create compare-and-swap' => sub {
  plan skip_all => 'Git::Libgit2 does not bind git_reference_create_matching'
    unless $has_create_matching;

  my $updated = $repo->reference_create(
    $create_ref, $c2,
    expected_old => $c1,
    message      => 'matching create update',
  );
  isa_ok $updated, ['Git::Native::Reference'],
    'matching update returns a Reference';
  is $updated->target->hex, $c2->hex,
    'matching expected OID updates the returned reference';
  is $repo->reference($create_ref)->target->hex, $c2->hex,
    'matching expected OID updates the stored reference';

  my $err = dies {
    $repo->reference_create( $create_ref, $c3, expected_old => $c1 );
  };
  isa_ok $err, ['Git::Native::Error'],
    'stale expected OID throws Git::Native::Error';
  ok $err->is_not_matched,
    'stale expected OID is distinguishable as not matched';
  is $repo->reference($create_ref)->target->hex, $c2->hex,
    'stale create leaves the stored reference unchanged';

  my $absent_ref = 'refs/cas/absent';
  my $created = $repo->reference_create(
    $absent_ref, $c1,
    expected_old => undef,
  );
  is $created->target->hex, $c1->hex,
    'expected_old undef atomically creates an absent reference';

  my $exists_err = dies {
    $repo->reference_create( $absent_ref, $c2, expected_old => undef );
  };
  ok $exists_err->is_not_matched,
    'expected_old undef rejects a reference that now exists';
  is $repo->reference($absent_ref)->target->hex, $c1->hex,
    'failed absent-only create leaves the reference unchanged';
};

my $set_ref = 'refs/cas/set-target';
$repo->reference_create( $set_ref, $c1 );

my $set = $repo->reference_set_target(
  $set_ref, $c2->hex,
  expected_old => $c1->hex,
  message      => 'matching set-target update',
);
isa_ok $set, ['Git::Native::Reference'],
  'reference_set_target returns a Reference';
is $set->target->hex, $c2->hex,
  'reference_set_target accepts hex OIDs and updates on a match';
is $repo->reference($set_ref)->target->hex, $c2->hex,
  'reference_set_target persists the matching update';

my $set_err = dies {
  $repo->reference_set_target( $set_ref, $c3, expected_old => $c1 );
};
isa_ok $set_err, ['Git::Native::Error'],
  'reference_set_target mismatch throws Git::Native::Error';
ok $set_err->is_not_matched,
  'reference_set_target mismatch is distinguishable as not matched';
is $repo->reference($set_ref)->target->hex, $c2->hex,
  'reference_set_target mismatch leaves the reference unchanged';

# git_reference_set_target is itself a CAS against the OID in the looked-up
# handle. This closes the race after Repository->reference_set_target performs
# its early expected-old comparison.
my $stale = $repo->reference($set_ref);
my $fresh = $repo->reference($set_ref);
$fresh->set_target($c3);
my $race_err = dies { $stale->set_target($c1) };
isa_ok $race_err, ['Git::Native::Error'],
  'a stale Reference set_target throws Git::Native::Error';
ok $race_err->is_not_matched,
  'the atomic stale-handle guard reports not matched';
is $repo->reference($set_ref)->target->hex, $c3->hex,
  'the stale handle cannot overwrite a concurrent update';

done_testing;

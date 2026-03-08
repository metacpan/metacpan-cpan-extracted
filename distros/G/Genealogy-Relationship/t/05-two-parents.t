use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin '$Bin';
use Genealogy::Relationship;
use lib "$Bin/lib";
use TestPersonWithParents;

# Build a family tree with two parents per person:
#
#   Grandpa (m) + Grandma (f)
#        |              |
#     Father (m)    Uncle (m)
#        |     \
#      Mother   \
#        |       \
#       Son (m)  Cousin (f)  <-- cousin is Uncle's child

my $grandpa = TestPersonWithParents->new(
  id      => 'gp',
  name    => 'Grandpa',
  gender  => 'm',
  parents => [],
);
my $grandma = TestPersonWithParents->new(
  id      => 'gm',
  name    => 'Grandma',
  gender  => 'f',
  parents => [],
);
my $father = TestPersonWithParents->new(
  id      => 'fa',
  name    => 'Father',
  gender  => 'm',
  parents => [$grandpa, $grandma],
);
my $uncle = TestPersonWithParents->new(
  id      => 'un',
  name    => 'Uncle',
  gender  => 'm',
  parents => [$grandpa, $grandma],
);
my $mother = TestPersonWithParents->new(
  id      => 'mo',
  name    => 'Mother',
  gender  => 'f',
  parents => [],
);
my $son = TestPersonWithParents->new(
  id      => 'so',
  name    => 'Son',
  gender  => 'm',
  parents => [$father, $mother],
);
my $cousin = TestPersonWithParents->new(
  id      => 'co',
  name    => 'Cousin',
  gender  => 'f',
  parents => [$uncle],
);
my $unrelated = TestPersonWithParents->new(
  id      => 'ur',
  name    => 'Unrelated',
  gender  => 'f',
  parents => [],
);

my $rel = Genealogy::Relationship->new;

# --- get_ancestors ---

my @ancestors = $rel->get_ancestors($grandpa);
is(scalar @ancestors, 0, 'Grandpa has no ancestors');

@ancestors = $rel->get_ancestors($father);
is(scalar @ancestors, 2, 'Father has two ancestors (grandpa and grandma)');
my %anc_ids = map { $_->id => 1 } @ancestors;
ok($anc_ids{gp}, 'Grandpa is an ancestor of Father');
ok($anc_ids{gm}, 'Grandma is an ancestor of Father');

@ancestors = $rel->get_ancestors($son);
is(scalar @ancestors, 4, 'Son has four ancestors (father, mother, grandpa, grandma)');
%anc_ids = map { $_->id => 1 } @ancestors;
ok($anc_ids{fa}, 'Father is an ancestor of Son');
ok($anc_ids{mo}, 'Mother is an ancestor of Son');
ok($anc_ids{gp}, 'Grandpa is an ancestor of Son');
ok($anc_ids{gm}, 'Grandma is an ancestor of Son');

# --- most_recent_common_ancestor ---

ok(my $mrca = $rel->most_recent_common_ancestor($son, $grandpa),
  'Got a most recent common ancestor between son and grandpa');
is($mrca->id, 'gp', 'Grandpa is the MRCA between Son and Grandpa');

ok($mrca = $rel->most_recent_common_ancestor($son, $grandma),
  'Got a most recent common ancestor between son and grandma');
is($mrca->id, 'gm', 'Grandma is the MRCA between Son and Grandma');

ok($mrca = $rel->most_recent_common_ancestor($son, $father),
  'Got a most recent common ancestor between son and father');
is($mrca->id, 'fa', 'Father is the MRCA between Son and Father');

ok($mrca = $rel->most_recent_common_ancestor($son, $mother),
  'Got a most recent common ancestor between son and mother');
is($mrca->id, 'mo', 'Mother is the MRCA between Son and Mother');

# Son and Cousin share Grandpa and Grandma as common ancestors (both at distance 4)
ok($mrca = $rel->most_recent_common_ancestor($son, $cousin),
  'Got a most recent common ancestor between son and cousin');
ok($mrca->id eq 'gp' || $mrca->id eq 'gm',
  'MRCA between son and cousin is grandpa or grandma');

ok($mrca = $rel->most_recent_common_ancestor($grandpa, $grandpa),
  'Got a most recent common ancestor between grandpa and grandpa');
is($mrca->id, 'gp', 'A person is their own MRCA');

throws_ok {
  $rel->most_recent_common_ancestor($son, $unrelated)
} qr/Can't find a common ancestor/,
  'Unrelated people do not have a common ancestor';

# --- get_relationship_coords ---

is_deeply([$rel->get_relationship_coords($son, $son)], [0, 0],
  'Son to himself is (0, 0)');

is_deeply([$rel->get_relationship_coords($son, $father)], [1, 0],
  'Son to father is (1, 0)');

is_deeply([$rel->get_relationship_coords($father, $son)], [0, 1],
  'Father to son is (0, 1)');

is_deeply([$rel->get_relationship_coords($son, $grandpa)], [2, 0],
  'Son to grandpa is (2, 0)');

is_deeply([$rel->get_relationship_coords($grandpa, $son)], [0, 2],
  'Grandpa to son is (0, 2)');

is_deeply([$rel->get_relationship_coords($son, $grandma)], [2, 0],
  'Son to grandma is (2, 0)');

# Son-to-cousin: both share a grandparent 2 levels up
my ($i, $j) = $rel->get_relationship_coords($son, $cousin);
is($i, 2, 'Son is 2 generations from the common ancestor with cousin');
is($j, 2, 'Cousin is 2 generations from the common ancestor with son');

throws_ok {
  $rel->get_relationship_coords($son, $unrelated)
} qr/Can't work out the relationship/,
  'Unrelated people do not have relationship coordinates';

# --- get_relationship ---

is($rel->get_relationship($son, $grandpa), 'Grandson',
  'Son is grandson of grandpa');
is($rel->get_relationship($son, $grandma), 'Grandson',
  'Son is grandson of grandma');
is($rel->get_relationship($grandpa, $son), 'Grandfather',
  'Grandpa is grandfather of son');
is($rel->get_relationship($grandma, $son), 'Grandmother',
  'Grandma is grandmother of son');
is($rel->get_relationship($son, $father), 'Son',
  'Son is son of father');
is($rel->get_relationship($father, $son), 'Father',
  'Father is father of son');
is($rel->get_relationship($cousin, $grandpa), 'Granddaughter',
  'Cousin is granddaughter of grandpa');
is($rel->get_relationship($cousin, $uncle), 'Daughter',
  'Cousin is daughter of uncle');
is($rel->get_relationship($cousin, $father), 'Niece',
  'Cousin is niece of father');
is($rel->get_relationship($father, $cousin), 'Uncle',
  'Father is uncle of cousin');

# --- get_relationship_ancestors ---

can_ok($rel, 'get_relationship_ancestors');

my $rels = $rel->get_relationship_ancestors($son, $grandpa);
is(scalar @$rels, 2, 'get_relationship_ancestors returns 2 lists');
is(scalar @{$rels->[0]}, 3, 'Son-to-grandpa path has 3 entries (son, father, grandpa)');
is(scalar @{$rels->[1]}, 1, 'Grandpa-to-grandpa path has 1 entry (grandpa)');
is($rels->[0][0]->id, $son->id, 'First entry in path1 is son');
is($rels->[0][-1]->id, $grandpa->id, 'Last entry in path1 is grandpa');
is($rels->[1][0]->id, $grandpa->id, 'Only entry in path2 is grandpa');

$rels = $rel->get_relationship_ancestors($father, $cousin);
is(scalar @$rels, 2, 'get_relationship_ancestors returns 2 lists');
is(scalar @{$rels->[0]}, 2, 'Father-to-MRCA path has 2 entries');
is(scalar @{$rels->[1]}, 3, 'Cousin-to-MRCA path has 3 entries');
is($rels->[0][0]->id, $father->id, 'Father is first in path1');
is($rels->[1][0]->id, $cousin->id, 'Cousin is first in path2');
# Both paths end at the same MRCA
is($rels->[0][-1]->id, $rels->[1][-1]->id, 'Both paths end at the same MRCA');

done_testing;

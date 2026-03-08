use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin '$Bin';
use Genealogy::Relationship;
use lib "$Bin/lib";
use TestPerson3;

# TestPerson3 uses custom attribute names:
#   person_id   instead of id
#   sex         instead of gender
#   progenitors instead of parents  (returns an arrayref)

my $grandpa = TestPerson3->new(
  person_id   => 'gp',
  name        => 'Grandpa',
  sex         => 'm',
  progenitors => [],
);
my $grandma = TestPerson3->new(
  person_id   => 'gm',
  name        => 'Grandma',
  sex         => 'f',
  progenitors => [],
);
my $father = TestPerson3->new(
  person_id   => 'fa',
  name        => 'Father',
  sex         => 'm',
  progenitors => [$grandpa, $grandma],
);
my $uncle = TestPerson3->new(
  person_id   => 'un',
  name        => 'Uncle',
  sex         => 'm',
  progenitors => [$grandpa, $grandma],
);
my $mother = TestPerson3->new(
  person_id   => 'mo',
  name        => 'Mother',
  sex         => 'f',
  progenitors => [],
);
my $son = TestPerson3->new(
  person_id   => 'so',
  name        => 'Son',
  sex         => 'm',
  progenitors => [$father, $mother],
);
my $cousin = TestPerson3->new(
  person_id   => 'co',
  name        => 'Cousin',
  sex         => 'f',
  progenitors => [$uncle],
);
my $unrelated = TestPerson3->new(
  person_id   => 'ur',
  name        => 'Unrelated',
  sex         => 'f',
  progenitors => [],
);

my $rel = Genealogy::Relationship->new(
  parents_field_name    => 'progenitors',
  identifier_field_name => 'person_id',
  gender_field_name     => 'sex',
);

# --- get_ancestors ---

my @ancestors = $rel->get_ancestors($grandpa);
is(scalar @ancestors, 0, 'Grandpa has no ancestors');

@ancestors = $rel->get_ancestors($father);
is(scalar @ancestors, 2, 'Father has two ancestors (grandpa and grandma)');
my %anc_ids = map { $_->person_id => 1 } @ancestors;
ok($anc_ids{gp}, 'Grandpa is an ancestor of Father');
ok($anc_ids{gm}, 'Grandma is an ancestor of Father');

@ancestors = $rel->get_ancestors($son);
is(scalar @ancestors, 4, 'Son has four ancestors');
%anc_ids = map { $_->person_id => 1 } @ancestors;
ok($anc_ids{fa}, 'Father is an ancestor of Son');
ok($anc_ids{mo}, 'Mother is an ancestor of Son');
ok($anc_ids{gp}, 'Grandpa is an ancestor of Son');
ok($anc_ids{gm}, 'Grandma is an ancestor of Son');

# --- most_recent_common_ancestor ---

ok(my $mrca = $rel->most_recent_common_ancestor($son, $grandpa),
  'Got a most recent common ancestor between son and grandpa');
is($mrca->person_id, 'gp', 'Grandpa is the MRCA between Son and Grandpa');

ok($mrca = $rel->most_recent_common_ancestor($son, $father),
  'Got a most recent common ancestor between son and father');
is($mrca->person_id, 'fa', 'Father is the MRCA between Son and Father');

ok($mrca = $rel->most_recent_common_ancestor($son, $cousin),
  'Got a most recent common ancestor between son and cousin');
ok($mrca->person_id eq 'gp' || $mrca->person_id eq 'gm',
  'MRCA between son and cousin is grandpa or grandma');

throws_ok {
  $rel->most_recent_common_ancestor($son, $unrelated)
} qr/Can't find a common ancestor/,
  'Unrelated people do not have a common ancestor';

# --- get_relationship_coords ---

is_deeply([$rel->get_relationship_coords($son, $son)], [0, 0],
  'Son to himself is (0, 0)');
is_deeply([$rel->get_relationship_coords($son, $father)], [1, 0],
  'Son to father is (1, 0)');
is_deeply([$rel->get_relationship_coords($son, $grandpa)], [2, 0],
  'Son to grandpa is (2, 0)');

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
is($rel->get_relationship($grandpa, $son), 'Grandfather',
  'Grandpa is grandfather of son');
is($rel->get_relationship($cousin, $father), 'Niece',
  'Cousin is niece of father');
is($rel->get_relationship($father, $cousin), 'Uncle',
  'Father is uncle of cousin');

# --- get_relationship_ancestors ---

can_ok($rel, 'get_relationship_ancestors');

my $rels = $rel->get_relationship_ancestors($father, $cousin);
is(scalar @$rels, 2, 'get_relationship_ancestors returns 2 lists');
is(scalar @{$rels->[0]}, 2, 'Father-to-MRCA path has 2 entries');
is(scalar @{$rels->[1]}, 3, 'Cousin-to-MRCA path has 3 entries');
is($rels->[0][0]->person_id, $father->person_id, 'Father is first in path1');
is($rels->[1][0]->person_id, $cousin->person_id, 'Cousin is first in path2');
is($rels->[0][-1]->person_id, $rels->[1][-1]->person_id, 'Both paths end at the same MRCA');

done_testing;

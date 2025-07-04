use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin '$Bin';
use Genealogy::Relationship;
use lib "$Bin/lib";
use TestPerson2;

my $grandfather = TestPerson2->new(
  person_id     => 'p1',
  name   => 'Grandfather',
  sex => 'm',
);
my $father = TestPerson2->new(
  person_id     => 'p2',
  name   => 'Father',
  progenitor => $grandfather,
  sex => 'm',
  );
my $son = TestPerson2->new(
  person_id     => 'p3',
  name   => 'Son',
  progenitor => $father,
  sex => 'm',
);
my $uncle = TestPerson2->new(
  person_id     => 'p4',
  name   => 'Uncle',
  progenitor => $grandfather,
  sex => 'm',
);
my $cousin = TestPerson2->new(
  person_id     => 'p5',
  name   => 'Cousin',
  progenitor => $uncle,
  sex => 'f',
);
my $unrelated_woman = TestPerson2->new(
  person_id     => 'p6',
  name   => 'Unrelated woman',
  sex => 'f',
);

my $rel = Genealogy::Relationship->new(
  parent_field_name     => 'progenitor',
  identifier_field_name => 'person_id',
  gender_field_name     => 'sex',
);

my @ancestors = $rel->get_ancestors($son);
is(@ancestors, 2, 'Son has two ancestors');

@ancestors = $rel->get_ancestors($father);
is(@ancestors, 1, 'Father has one ancestor');

@ancestors = $rel->get_ancestors($grandfather);
is(@ancestors, 0, 'Grandfather has no ancestors');

ok(my $mrca = $rel->most_recent_common_ancestor($son, $cousin),
  'Got a most recent common ancestor between son and cousin');
is($mrca->name, 'Grandfather',
  'Got the right most recent common ancestor between son and cousin');

ok($mrca = $rel->most_recent_common_ancestor($son, $father),
  'Got a most recent common ancestor between son and father');
is($mrca->name, 'Father',
  'Got the right most recent common ancestor between son and father');

ok($mrca = $rel->most_recent_common_ancestor($father, $son),
  'Got a most recent common ancestor between father and son');
is($mrca->name, 'Father',
  'Got the right most recent common ancestor between father and son');

ok($mrca = $rel->most_recent_common_ancestor($grandfather, $grandfather),
   'Got a most recent common ancestor between grandfather and grandfather');
is($mrca->name, 'Grandfather',
  'A person themself can be their own most recent common ancestor');

throws_ok {
  $rel->most_recent_common_ancestor( $son, $unrelated_woman )
} qr/Can't find a common ancestor/,
  'Unrelated people do not have a common ancestor';

is_deeply([$rel->get_relationship_coords($son, $son)], [0, 0],
  'Got right relationship coords between son and himself');
is_deeply([$rel->get_relationship_coords($son, $grandfather)], [2, 0],
  'Got right relationship coords between son and grandfather');
is_deeply([$rel->get_relationship_coords($grandfather, $son)], [0, 2],
  'Got right relationship coords between grandfather and son');
is_deeply([$rel->get_relationship_coords($son, $cousin)], [2, 2],
  'Got right relationship coords between son and cousin');
is_deeply([$rel->get_relationship_coords($son, $cousin)], [2, 2],
  'Got right relationship coords between cousin and son');

throws_ok {
  $rel->get_relationship_coords( $son, $unrelated_woman )
} qr/Can't work out the relationship/,
  'Unrelated people do not have relationship coordinates';

is($rel->get_relationship($son, $grandfather), 'Grandson',
  'Son is the grandson of the grandfather');
is($rel->get_relationship($cousin, $grandfather), 'Granddaughter',
  'Cousin is the granddaughter of the grandfather');
is($rel->get_relationship($grandfather, $son), 'Grandfather',
  'Grandfather is the grandfather of the son');
is($rel->get_relationship($grandfather, $cousin), 'Grandfather',
  'Grandfather is the grandfather of the cousin');
is($rel->get_relationship($cousin, $father), 'Niece',
  'Cousin is the niece of the father');
is($rel->get_relationship($father, $cousin), 'Uncle',
  'Father is the uncle of the niece');

can_ok($rel, 'get_relationship_ancestors');
my $rels = $rel->get_relationship_ancestors($father, $cousin);
is(@$rels, 2, 'Correct number of items from get_relationship_ancestors()');
is(@{$rels->[0]}, 2, 'Correct number of items from get_relationship_ancestors()');
is(@{$rels->[1]}, 3, 'Correct number of items from get_relationship_ancestors()');
$mrca = $rel->most_recent_common_ancestor($father, $cousin);
is($rels->[0][0]->person_id, $father->person_id, 'Father is first');
is($rels->[0][-1]->person_id, $mrca->person_id, 'MRCA is last');
is($rels->[1][0]->person_id, $cousin->person_id, 'Cousin is first');
is($rels->[1][-1]->person_id, $mrca->person_id, 'MRCA is last');
done_testing;

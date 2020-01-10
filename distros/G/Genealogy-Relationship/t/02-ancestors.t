use strict;
use warnings;

use Test::More;
use FindBin '$Bin';
use Genealogy::Relationship;
use lib "$Bin/lib";
use TestPerson;

my $grandfather = TestPerson->new(
  id     => 1,
  name   => 'Grandfather',
  gender => 'm',
);
my $father = TestPerson->new(
  id     => 2,
  name   => 'Father',
  parent => $grandfather,
  gender => 'm',
  );
my $son = TestPerson->new(
  id     => 3,
  name   => 'Son',
  parent => $father,
  gender => 'm',
);
my $uncle = TestPerson->new(
  id     => 4,
  name   => 'Uncle',
  parent => $grandfather,
  gender => 'm',
);
my $cousin = TestPerson->new(
  id     => 5,
  name   => 'Cousin',
  parent => $uncle,
  gender => 'f',
);

my $rel = Genealogy::Relationship->new;

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

done_testing;

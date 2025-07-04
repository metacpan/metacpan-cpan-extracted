use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin '$Bin';
use Genealogy::Relationship;
use lib "$Bin/lib";
use TestPerson;

my @generations;

push @generations, TestPerson->new(
  id => 1,
  name => 'Person 1',
  gender => 'm',
);

my @expected = (
  [ undef, undef ],
  [ 'Brother',        'Brother'],
  [ 'First cousin',   'Uncle' ],
  [ 'Second cousin',  'Great uncle' ],
  [ 'Third cousin',   'Great, great uncle' ],
  [ 'Fourth cousin',  '3 x great uncle' ],
  [ 'Fifth cousin',   '4 x great uncle' ],
  [ 'Sixth cousin',   '5 x great uncle' ],
  [ 'Seventh cousin', '6 x great uncle' ],
  [ 'Eighth cousin',  '7 x great uncle' ],
  [ 'Ninth cousin',   '8 x great uncle' ],
);

for my $g (1 .. 10) {
  my @parents;
  if (ref $generations[-1] eq 'ARRAY') {
    @parents = @{$generations[-1]};
  } else {
    @parents = ($generations[-1]) x 2;
  }

  my @ids = ($parents[0]->id + 1, $parents[0]->id + 100);

  my $p1 = TestPerson->new(
    id => $ids[0],
    name => "Person $ids[0]",
    parent => $parents[0],
    gender => 'm',
  );

  my $p2 = TestPerson->new(
    id => $ids[1],
    name => "Person $ids[1]",
    parent => $parents[1],
    gender => 'm',
  );

  push @generations, [$p1, $p2];
}

my $rel = Genealogy::Relationship->new;

for (1 .. 10) {
  is($rel->get_relationship(@{$generations[$_]}), $expected[$_][0]);
  is($rel->get_relationship($generations[1][0], $generations[$_][1]), $expected[$_][1]);
}

is($rel->get_relationship($generations[8][0], $generations[10][1]),
   'Seventh cousin twice removed');
is($rel->get_relationship($generations[3][0], $generations[9][1]),
   'Second cousin six times removed');
is($rel->get_relationship($generations[9][0], $generations[9][1]),
   'Eighth cousin');
is($rel->get_relationship($generations[8][0], $generations[5][1]),
   'Fourth cousin three times removed');

# can_ok($rel, 'abbr');

# Test a higher number for abbr
$rel = Genealogy::Relationship->new(abbr => 4);
is($rel->get_relationship($generations[1][0], $generations[5][1]), 'Great, great, great uncle');
is($rel->get_relationship($generations[1][0], $generations[6][1]), '4 x great uncle');

# Turn off abbr
$rel = Genealogy::Relationship->new(abbr => 0);
is($rel->get_relationship($generations[1][0], $generations[3][1]), 'Great uncle');
is($rel->get_relationship($generations[1][0], $generations[4][1]), 'Great, great uncle');
is($rel->get_relationship($generations[1][0], $generations[5][1]), 'Great, great, great uncle');


done_testing;


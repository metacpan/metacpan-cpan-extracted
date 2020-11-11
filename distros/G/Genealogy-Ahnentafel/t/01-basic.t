use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok 'Genealogy::Ahnentafel' }

my @gender_tests = qw[dummy Unknown Male Female Male Female Male Female];

foreach (1 .. $#gender_tests) {
  is(ahnen($_)->gender, $gender_tests[$_],
     "Gender for Ahnentafel $_ is correct");
}

my @generation_tests = (
  [1, 1], [3, 2], [5, 3], [11, 4], [24, 5], [40, 6], [98, 7],
);

foreach (@generation_tests) {
  is(ahnen($_->[0])->generation, $_->[1],
     "Ahnentafel $_->[0] is in generation $_->[1]");
}

my @description_tests = (
  [ Person => 1 ],
  [ Father => 2 ],
  [ Mother => 3 ],
  [ Grandfather => 4 ],
  [ Grandmother => 5 ],
  [ Grandfather => 6 ],
  [ Grandmother => 7 ],
  [ 'Great Grandfather' => 8 ],
  [ 'Great Grandmother' => 9 ],
);

foreach (@description_tests) {
  is(ahnen($_->[1])->description, $_->[0], "Person $_->[1] is a $_->[0]");
}

for (qw[1 4 7 14 81 123]) {
  ok(ahnen($_), "$_ is a valid Ahnentafel");
}

my @generation_tests2 = (
  [ 1, 1, 1, 1, 1 ],
  [ 2, 2, 1, 3, '' ],
  [ 127, 64, '', 127, 1],
);

foreach (@generation_tests2) {
  my $ahnen = ahnen($_->[0]);
  is($ahnen->first_in_generation, $_->[1], "First in generation for $_->[0]");
  is($ahnen->is_first_in_generation, $_->[2], "Is first in generation for $_->[0]");
  is($ahnen->last_in_generation, $_->[3], "Last in generation for $_->[0]");
  is($ahnen->is_last_in_generation, $_->[4], "Is first in generation for $_->[0]");
}

my @parent_tests = (
  [ 1, 2, 3 ],
  [ 2, 4, 5 ],
  [ 5, 10, 11 ],
  [ 23, 46, 47 ],
);

foreach (@parent_tests) {
  my $ahnen = ahnen($_->[0]);
  is($ahnen->father, $_->[1], "$_->[0]'s father is $_->[1]");
  is($ahnen->mother, $_->[2], "$_->[0]'s mother is $_->[2]");
}

my $grandfather = ahnen(4);
my $ancestry = $grandfather->ancestry;
is(@$ancestry, 3, 'Three generations in ancestry');
is($grandfather->ancestry_string, 'Person, Father, Grandfather',
   'Correct ancestry string');

throws_ok { ahnen() }
          qr/did not pass type constraint/, 'Correct error thrown';

throws_ok { ahnen(0) }
          qr/did not pass type constraint/, 'Correct error thrown';

throws_ok { ahnen(-1) }
          qr/did not pass type constraint/, 'Correct error thrown';

throws_ok { ahnen(' ') }
          qr/did not pass type constraint/, 'Correct error thrown';

throws_ok { ahnen('A string') }
          qr/did not pass type constraint/, 'Correct error thrown';

done_testing;

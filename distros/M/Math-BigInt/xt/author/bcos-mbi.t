# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigInt;

$| = 1;

my $cases =
  [
   [  'NaN', 'NaN' ],
   [ '-inf', 'NaN' ],
   [ '-150',   '0' ],
   [  '-10',   '0' ],
   [   '-5',   '0' ],
   [   '-1',   '0' ],
   [    '0',   '1' ],
   [    '1',   '0' ],
   [   ' 5',   '0' ],
   [   '10',   '0' ],
   [  '510',   '0' ],
   [  'inf', 'NaN' ],
  ];

for my $case (@$cases) {
    my ($x, $want) = @$case;

    my $test = qq|Math::BigInt -> new("$x") -> bcos();|;

    note "\n", $test, "\n\n";
    my $y = eval $test;
    die $@ if $@;

    is($y, $want, $test);
}

done_testing();

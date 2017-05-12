use strict;
use warnings;

use Test::More 'no_plan';

use_ok('Math::TotalBuilder');

my %tender = (
  hundred => 10000,
  fifty   =>  5000,
  twenty  =>  2000,
  ten     =>  1000,
  five    =>   500,
  two     =>   200,
  one     =>   100,
  half    =>    50,
  quarter =>    25,
  dime    =>    10,
  nickel  =>     5,
  penny   =>     1
);

my %time = (
  week    => 604800,
  day     =>  86400,
  hour    =>   3600,
  minute  =>     60,
  second  =>      1
);

ok(build(\%tender, 10000),   "can build a simple total");
ok(! build(\%tender,   0),   "no units in a zero sum");

ok(
  eq_hash( { build(\%tender, 10000) }, { hundred => 1 }),
  "one hundred makes 10000 cents"
);

ok(
  eq_hash( { build(\%time, 1382400) }, { week => 2, day => 2 }),
  "fortnight and two days"
);

ok(
  eq_hash( { build(\%tender, 4) }, { penny => 4 }),
  "four cents is four pennies"
);

ok(
  eq_hash(
	{ fifty => 1, twenty => 2, five => 1, two => 2, half => 1, quarter => 1, dime => 2, penny => 4 },
	{ build(\%tender, 9999) }
  ),
  "units for 9999 cents"
);

my $nnnn = { fifty => 1, twenty => 2, five => 1, two => 2, half => 1, quarter
=> 1, dime => 2, penny => 4 };

is(total(\%tender, $nnnn), 9999, "ninety nine from units");

eval { total(\%tender, { ten => 1, three => 3, dime => 9, penny => 9 }); };
ok( $@, "queer as a three dollar bill");

ok(
  eq_hash(
    { pound => 1, crown => 2, shilling => 1, _remainder => 10 },
	{ build({ pound => 240, crown => 60, shilling => 12}, 382) }
  ),
  "can't build 382d total with no penny"
);


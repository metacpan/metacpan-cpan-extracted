use Test::More tests => 6;

use strict;
use warnings;

use_ok('Math::TotalBuilder');

my %coins = (
  half    =>    50,
  quarter =>    25,
  dime    =>    10,
  nickel  =>     5,
  penny   =>     1
);

ok(build(\%coins, 982),   "can build a simple total");
ok(! build(\%coins, 0),   "no units in a zero sum");

ok(
  eq_hash( { build(\%coins, 10000, sub { nothing => 1 }) }, { nothing => 1 }),
  "the cheating builder: 1 nothing"
);

my $contrived = [
	sub { nonsense => 2, _remainder => 2 },
	sub { fooferal => 1, _remainder => 3 },
	sub { fakeunit => 9, _remainder => 1 },
	sub { tuppence => 6, _remainder => 8 }
];

ok(
  eq_hash(
		{ build(\%coins, 10, $contrived) },
		{ fakeunit => 9, _remainder => 1 }
	),
  "contrived coderef list"
);

eval { build(\%coins, 10, \%coins) };
ok($@, "third arg to build must be code or array ref");

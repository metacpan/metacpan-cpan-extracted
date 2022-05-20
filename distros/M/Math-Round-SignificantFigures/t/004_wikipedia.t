use strict;
use warnings;
use Test::More tests => 17;
use Math::Round::SignificantFigures qw{:figs};

diag("Tests from Wikipedia");

is(roundsigfigs(12.345, 6), 12.345);
is(roundsigfigs(12.345, 5), 12.345);
is(roundsigfigs(12.345, 4), 12.35);
is( ceilsigfigs(12.345, 4), 12.35);
is(floorsigfigs(12.345, 4), 12.34);
is(roundsigfigs(12.345, 3), 12.3);
is(roundsigfigs(12.345, 2), 12);
is(roundsigfigs(12.345, 1), 10);

is(roundsigfigs(0.012345, 7), 0.01234500);
is(roundsigfigs(0.012345, 6), 0.0123450);
is(roundsigfigs(0.012345, 5), 0.012345);
is(roundsigfigs(0.012345, 4), 0.01235);
is( ceilsigfigs(0.012345, 4), 0.01235);
is(floorsigfigs(0.012345, 4), 0.01234);
is(roundsigfigs(0.012345, 3), 0.0123);
is(roundsigfigs(0.012345, 2), 0.012);
is(roundsigfigs(0.012345, 1), 0.01);

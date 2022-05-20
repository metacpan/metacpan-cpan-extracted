use strict;
use warnings;
use Test::More tests => 13;
use Math::Round::SignificantFigures qw{:all};

is(roundsigfigs(555.555, 1), 600);
is(ceilsigfigs(555.555, 1), 600);
is(floorsigfigs(555.555, 1), 500);

is(roundsigdigs(555.555, 1), 600);
is(ceilsigdigs(555.555, 1), 600);
is(floorsigdigs(555.555, 1), 500);

is(roundsigdigs( 12.5555, 3),  12.6);
is(roundsigdigs(-12.5555, 3), -12.6);

is(ceilsigdigs( 12.5555, 3),  12.6);
is(ceilsigdigs(-12.5555, 3), -12.5);

is(floorsigdigs( 12.5555, 3),  12.5);
is(floorsigdigs(-12.5555, 3), -12.6);

is(ceilsigfigs(42.34523, 1), 50, "why I wrote this package");

use strict;
use warnings;
use Test::More tests => 9;
use Math::Round::SignificantFigures qw{:figs};

is(roundsigfigs(555.555, 1), 600);
is(ceilsigfigs(555.555, 1), 600);
is(floorsigfigs(555.555, 1), 500);

is(eval{roundsigdigs(555.555, 1)}, undef);
like($@, qr/Undefined subroutine/);
is(eval{floorsigdigs(555.555, 1)}, undef);
like($@, qr/Undefined subroutine/);
is(eval{ceilsigdigs(555.555, 1)}, undef);
like($@, qr/Undefined subroutine/);

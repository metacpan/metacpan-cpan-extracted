use strict;
use warnings;
use Test::More tests => 9;
use Math::Round::SignificantFigures qw{:digs};

is(roundsigdigs(555.555, 1), 600);
is(ceilsigdigs(555.555, 1), 600);
is(floorsigdigs(555.555, 1), 500);

is(eval{roundsigfigs(555.555, 1)}, undef);
like($@, qr/Undefined subroutine/);
is(eval{floorsigfigs(555.555, 1)}, undef);
like($@, qr/Undefined subroutine/);
is(eval{ceilsigfigs(555.555, 1)}, undef);
like($@, qr/Undefined subroutine/);

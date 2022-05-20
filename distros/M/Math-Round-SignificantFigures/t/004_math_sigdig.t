use strict;
use warnings;
use Test::More tests => 4;
use Math::Round::SignificantFigures qw{roundsigdigs};

diag("Tests from Math::SigDig");

is(roundsigdigs(12.3456789    ), 12.3);
is(roundsigdigs(12.3456789  ,4), 12.35);
is(roundsigdigs(-12.345e-6789,2), -12e-6789);
is(roundsigdigs(12.00456789  ,4), 12.00);

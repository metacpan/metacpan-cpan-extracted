use strict;
use Test::More;

my $warnings;

BEGIN {
    $^W = 1;
    $warnings = 0;
    $SIG{__WARN__} = sub { $warnings++ };
}

use Math::Vector::Real;

BEGIN { undef $SIG{__WARN__} }

is($warnings, 0, '0 warnings');

done_testing;


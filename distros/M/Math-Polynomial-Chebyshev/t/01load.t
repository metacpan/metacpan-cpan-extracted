#!perl

use strict;             # restrict unsafe constructs
use warnings;           # enable optional warnings

use Test::More tests => 2;

BEGIN {
    use_ok('Math::Polynomial::Chebyshev');
    use_ok('Math::Polynomial::Chebyshev2');
};

#!/usr/bin/env perl
use strict;

use Test::More tests => 3;

BEGIN {
    use_ok( 'Math::Primality' );
    use_ok( 'Math::Primality::AKS' );
    use_ok( 'Math::Primality::BigPolynomial' );
}

diag( "Testing Math::Primality $Math::Primality::VERSION, Perl $], $^X" );

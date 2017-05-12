#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dezi::Stats' );
}

diag( "Testing Dezi::Stats $Dezi::Stats::VERSION, Perl $], $^X" );

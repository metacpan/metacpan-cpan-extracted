#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'Ed2k_link' );
}

diag( "Testing Ed2k_link $Ed2k_link::VERSION, Perl $], $^X" );

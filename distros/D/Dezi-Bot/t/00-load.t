#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dezi::Bot' );
}

diag( "Testing Dezi::Bot $Dezi::Bot::VERSION, Perl $], $^X" );

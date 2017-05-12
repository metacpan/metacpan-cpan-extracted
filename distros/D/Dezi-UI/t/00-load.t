#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dezi::UI' );
}

diag( "Testing Dezi::UI $Dezi::UI::VERSION, Perl $], $^X" );

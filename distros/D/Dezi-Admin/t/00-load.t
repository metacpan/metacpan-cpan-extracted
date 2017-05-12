#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dezi::Admin' );
}

diag( "Testing Dezi::Admin $Dezi::Admin::VERSION, Perl $], $^X" );

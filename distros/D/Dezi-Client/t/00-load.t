#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dezi::Client' );
}

diag( "Testing Dezi::Client $Dezi::Client::VERSION, Perl $], $^X" );

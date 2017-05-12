#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dezi::MultiTenant' );
}

diag( "Testing Dezi::MultiTenant $Dezi::MultiTenant::VERSION, Perl $], $^X" );

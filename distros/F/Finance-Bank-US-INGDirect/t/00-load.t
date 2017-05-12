#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Bank::US::INGDirect' );
}

diag( "Testing Finance::Bank::US::INGDirect $Finance::Bank::US::INGDirect::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lvalue' );
}

diag( "Testing Lvalue $Lvalue::VERSION, Perl $], $^X" );

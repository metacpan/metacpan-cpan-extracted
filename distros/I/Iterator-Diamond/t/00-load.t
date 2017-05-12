#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Iterator::Diamond' );
}

diag( "Testing Iterator::Diamond $Iterator::Diamond::VERSION, Perl $], $^X" );

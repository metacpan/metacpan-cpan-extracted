#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'List::Gen' );
}

diag( "Testing List::Gen $List::Gen::VERSION, Perl $], $^X" );

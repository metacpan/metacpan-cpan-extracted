#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Guard::State::Washington' ) || print "Bail out!\n";
}

diag( "Testing Guard::State::Washington $Guard::State::Washington::VERSION, Perl $], $^X" );

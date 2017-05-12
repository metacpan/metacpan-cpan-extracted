#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Ham::Resources::Utils' ) || print "Bail out!\n";
}

diag( "Testing Ham::Resources::Utils $Ham::Resources::Utils::VERSION, Perl $], $^X" );

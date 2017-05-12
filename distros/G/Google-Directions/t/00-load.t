#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Google::Directions::Client' ) || print "Bail out!\n";
}

diag( "Testing Google::Directions::Client $Google::Directions::Client::VERSION, Perl $], $^X" );

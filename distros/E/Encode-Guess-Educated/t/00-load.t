#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Encode::Guess::Educated' ) || print "Bail out!\n";
}

diag( "Testing Encode::Guess::Educated $Encode::Guess::Educated::VERSION, Perl $], $^X" );

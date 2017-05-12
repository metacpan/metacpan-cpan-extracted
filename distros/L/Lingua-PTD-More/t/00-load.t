#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::PTD::More' ) || print "Bail out!\n";
}

diag( "Testing Lingua::PTD::More $Lingua::PTD::More::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Encode::Deep' ) || print "Bail out!\n";
}

diag( "Testing Encode::Deep $Encode::Deep::VERSION, Perl $], $^X" );

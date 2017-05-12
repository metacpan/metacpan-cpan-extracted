#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Encode::Safename' ) || print "Bail out!\n";
}

diag( "Testing Encode::Safename $Encode::Safename::VERSION, Perl $], $^X" );

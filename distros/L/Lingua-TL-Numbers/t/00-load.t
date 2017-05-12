#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::TL::Numbers' ) || print "Bail out!\n";
}

diag( "Testing Lingua::TL::Numbers $Lingua::TL::Numbers::VERSION, Perl $], $^X" );

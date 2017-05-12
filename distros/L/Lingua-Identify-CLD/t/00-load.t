#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::Identify::CLD' ) || print "Bail out!\n";
}

diag( "Testing Lingua::Identify::CLD $Lingua::Identify::CLD::VERSION, Perl $], $^X" );

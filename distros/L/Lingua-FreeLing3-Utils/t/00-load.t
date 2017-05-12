#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::FreeLing3::Utils' ) || print "Bail out!\n";
}

diag( "Testing Lingua::FreeLing3::Utils $Lingua::FreeLing3::Utils::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::Orthon' ) || print "Bail out!\n";
}

diag( "Testing Lingua::Orthon $Lingua::Orthon::VERSION, Perl $], $^X" );

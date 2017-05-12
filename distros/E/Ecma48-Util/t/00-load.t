#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Ecma48::Util' ) || print "Bail out!\n";
}

diag( "Testing Ecma48::Util $Ecma48::Util::VERSION, Perl $], $^X" );

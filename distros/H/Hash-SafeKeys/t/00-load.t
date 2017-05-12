#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hash::SafeKeys' ) || print "Bail out!\n";
}

diag( "Testing Hash::SafeKeys $Hash::SafeKeys::VERSION, Perl $], $^X" );


#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Math::RatioResize' ) || print "Bail out!\n";
}

diag( "Testing Math::RatioResize $Math::RatioResize::VERSION, Perl $], $^X" );

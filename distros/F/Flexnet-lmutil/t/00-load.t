#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Flexnet::lmutil' ) || print "Bail out!\n";
}

diag( "Testing Flexnet::lmutil $Flexnet::lmutil::VERSION, Perl $], $^X" );

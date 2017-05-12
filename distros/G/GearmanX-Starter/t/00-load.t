#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'GearmanX::Starter' ) || print "Bail out!\n";
}

diag( "Testing GearmanX::Starter $GearmanX::Starter::VERSION, Perl $], $^X" );

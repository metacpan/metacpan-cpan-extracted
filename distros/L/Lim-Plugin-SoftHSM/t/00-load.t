#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lim::Plugin::SoftHSM' ) || print "Bail out!\n";
}

diag( "Testing Lim::Plugin::SoftHSM $Lim::Plugin::SoftHSM::VERSION, Perl $], $^X" );

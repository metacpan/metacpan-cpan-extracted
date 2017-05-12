#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lim::Plugin::Zonalizer' ) || print "Bail out!\n";
}

diag( "Testing Lim::Plugin::Zonalizer $Lim::Plugin::Zonalizer::VERSION, Perl $], $^X" );

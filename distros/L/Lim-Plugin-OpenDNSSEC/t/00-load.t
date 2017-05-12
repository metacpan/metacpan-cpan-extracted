#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lim::Plugin::OpenDNSSEC' ) || print "Bail out!\n";
}

diag( "Testing Lim::Plugin::OpenDNSSEC $Lim::Plugin::OpenDNSSEC::VERSION, Perl $], $^X" );

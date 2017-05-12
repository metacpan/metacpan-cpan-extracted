#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Ham::Packet::DXSpider' ) || print "Bail out!\n";
}

diag( "Testing Ham::Packet::DXSpider $Ham::Packet::DXSpider::VERSION, Perl $], $^X" );

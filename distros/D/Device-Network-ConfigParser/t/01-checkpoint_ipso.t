#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Device::Network::ConfigParser::CheckPoint::Gaia qw{get_parser parse_config};

my @ipso_tests = (
    { 
        config  => 'set interface eth0 vlan 1200',
        desc    => 'Interface VLAN'
    },
    { 
        config  => 'set interface eth0 state on',
        desc    => 'Interface State'
    },
    { 
        config  => 'set interface eth0 comments "This is a comment"',
        desc    => 'Interface Comments'
    },
    { 
        config  => 'set interface eth0 mtu 1300',
        desc    => 'Interface MTU'
    },
    { 
        config  => 'set interface eth0 ipv4-address 192.168.1.1 mask-length 24',
        desc    => 'Interface IPv4 Address'
    },
    { 
        config  => 'set interface eth0 auto-negotiation on',
        desc    => 'Interface Autonegotiation'
    },
    { 
        config  => 'set interface eth0 link-speed 10M/Full' ,
        desc    => 'Interface Link Speed'
    },
);

plan tests => 1 + @ipso_tests;

ok( my $parser = get_parser(), 'Generate Parser' );

for my $test (@ipso_tests) {
    ok( $parser->startrule( $test->{config} ), $test->{desc} );
}



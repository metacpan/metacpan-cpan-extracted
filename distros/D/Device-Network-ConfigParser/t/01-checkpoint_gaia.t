#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

my @interface_tests = (
    {
        test        => q{set interface eth0 ipv4-address 192.0.2.1 mask-length 24},
        p_proc      => {'interface' => [ { 'ipv4_mask' => '24', 'ipv4_address' => '192.0.2.1', 'name' => 'eth0' } ]},
        desc        => q{set interface IP and mask}
    },
    {
        test        => q{set interface eth0 comments "Comment"},
        p_proc      => {'interface' => [ { comment => '"Comment"', name => 'eth0' } ]},
        desc        => q{set interface comment}
    },
    {
        test        => q{set interface eth0 state on},
        p_proc      => {'interface' => [ { state=> 'on', name => 'eth0' } ]},
        desc        => q{set interface state on}
    },
    {
        test        => q{set interface eth0 link-speed 100M/full},
        p_proc      => {'interface' => [ { link_speed => '100M/full', name => 'eth0' } ]},
        desc        => q{set interface link-speed}
    },
    {
        test        => q{set interface eth0 auto-negotiation off},
        p_proc      => {'interface' => [ { auto_negotiation => 'off', name => 'eth0' } ]},
        desc        => q{set interface auto-neg}
    },
    {
        test        => q{set interface eth0 mtu 1500},
        p_proc      => {'interface' => [ { mtu => '1500', name => 'eth0' } ]},
        desc        => q{set interface auto-neg}
    },
    {
        test        => q{
                            set interface eth0 ipv4-address 192.0.2.1 mask-length 24
                            set interface eth0 comments "Comment"
                            set interface eth0 state on
                            set interface eth0 link-speed 100M/full
                            set interface eth0 auto-negotiation off
                            set interface eth0 mtu 1500
                        },
        p_proc      => {
            'interface' => [ {
                ipv4_mask => '24', ipv4_address => '192.0.2.1', name => 'eth0',
                comment => '"Comment"',
                state => 'on',
                link_speed => '100M/full',
                auto_negotiation => 'off',
                mtu => '1500'
            } ]
        },
        desc        => q{full interface config consolidation}
    },
);




my @static_route_tests = (
    {
        test        => q{set static-route 192.0.2.0/25 nexthop gateway address 192.0.2.254 on},
        p_proc      => {
            'static_route' => [{
                    'status' => 'on',
                    'nexthop_type' => 'address',
                    'destination' => '192.0.2.0/25',
                    'nexthop' => '192.0.2.254'
                }]
        },
        desc        => q{set static-route nexthop ip}
    },
    {
        test        => q{set static-route default nexthop gateway address 192.0.2.254 on},
        p_proc      => {
            'static_route' => [{
                    'status' => 'on',
                    'nexthop_type' => 'address',
                    'destination' => 'default',
                    'nexthop' => '192.0.2.254'
                }]
        },
        desc        => q{set static-route default nexthop ip}
    },
    {
        test        => q{set static-route 192.0.2.0/25 nexthop gateway logical eth0 on},
        p_proc      => {
            'static_route' => [{
                    'status' => 'on',
                    'nexthop_type' => 'interface',
                    'destination' => '192.0.2.0/25',
                    'nexthop' => 'eth0'
                }]
        },
        desc        => q{set static-route nexthop interface}
    },
    {
        test        => q{set static-route default nexthop gateway logical eth0 on},
        p_proc      => {
            'static_route' => [{
                    'status' => 'on',
                    'nexthop_type' => 'interface',
                    'destination' => 'default',
                    'nexthop' => 'eth0'
                }]
        },
        desc        => q{set static-route default nexthop interface}
    },
    {
        test        => q{set static-route 192.0.2.0/25 nexthop blackhole},
        p_proc      => {
            'static_route' => [{
                    'nexthop_type' => 'blackhole',
                    'destination' => '192.0.2.0/25',
                }]
        },
        desc        => q{set static-route nexthop blackhole}
    },
    {
        test        => q{set static-route 192.0.2.0/25 nexthop reject},
        p_proc      => {
            'static_route' => [{
                    'nexthop_type' => 'reject',
                    'destination' => '192.0.2.0/25',
                }]
        },
        desc        => q{set static-route nexthop reject}
    },
);


my @all_tests = (
    @interface_tests,
    @static_route_tests,
);

# + 1 is for the use_ok()
plan tests => 1 + @all_tests; 

use_ok( 'Device::Network::ConfigParser::CheckPoint::Gaia', qw{get_parser parse_config post_process} ) || print "Bail out!\n";

my $parser = get_parser();

# Test interface parsing
for my $test (@all_tests) {
    my $parsed = parse_config($parser, $test->{test});
    my $post_processed = post_process($parsed);

    is_deeply( $post_processed, $test->{p_proc}, $test->{desc} );
}
    



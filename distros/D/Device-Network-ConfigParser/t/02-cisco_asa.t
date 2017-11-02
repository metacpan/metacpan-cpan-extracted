#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

my @small_config_items = (
    {
        test        => q{hostname Hostname},
        p_proc      => [ { type => 'hostname', config => 'Hostname' } ],
        desc        => q{Standard Hostname}
    },
    {
        test        => q{domain-name domain.local},
        p_proc      => [ { type => 'domain_name', config => 'domain.local' } ],
        desc        => q{Standard Domain Name}
    },
    {
        test        => q{name 192.0.2.1 Named_Host},
        p_proc      => [ { type => 'name', config => { alias => 'Named_Host', ip => '192.0.2.1' } } ],
        desc        => q{Name Alias}
    },
);

my @routes = (
    {
        test        => q{route inside 192.0.2.0 255.255.255.128 192.0.2.129 1},
        p_proc      => [ { type => 'route', config => { 
                                        interface => 'inside',
                                        destination => '192.0.2.0/255.255.255.128', 
                                        next_hop => '192.0.2.129',
                                        metric => '1',
                                        track_id => ''
                                    } } ],
        desc        => q{Standard Route}
    },
    {
        test        => q{route inside 192.0.2.0 255.255.255.128 192.0.2.129 1 track 20},
        p_proc      => [ { type => 'route', config => { 
                                        interface => 'inside',
                                        destination => '192.0.2.0/255.255.255.128', 
                                        next_hop => '192.0.2.129',
                                        metric => '1',
                                        track_id => '20'
                                    } } ],
        desc        => q{Tracked Route}
    },
    {
        test        => q{route inside IP_ALIAS_1 255.255.255.128 IP_ALIAS_2 1},
        p_proc      => [ { type => 'route', config => { 
                                        interface => 'inside',
                                        destination => 'IP_ALIAS_1/255.255.255.128', 
                                        next_hop => 'IP_ALIAS_2',
                                        metric => '1',
                                        track_id => ''
                                    } } ],
        desc        => q{Route with Hosts not IPs}
    },
);

my @nat = (
    {
        test        => q{nat (INSIDE,OUTSIDE) source static rs ms destination static md rd},
        p_proc      => [ {
						'config' => {
                        	'int_interface' => 'INSIDE',
                            'ext_interface' => 'OUTSIDE',
                            'source_nat' => {
                                'real_src' => 'rs',
                                'mapped_src' => 'ms',
                                'type' => 'static',
                            },
                          	'destination_nat' => {
                            	'mapped_dst' => 'md',
                                'real_dst' => 'rd',
                                'type' => 'static',
                            },
                            'proxy_arp' => 1,
                            'route_lookup' => 0,
                            'description' => ''
                        },
                        'type' => 'nat' }],
        desc        => q{Static Source and Dest NAT}
    },
    {
        test        => q{nat (INSIDE,OUTSIDE) source static rs ms destination static md rd no-proxy-arp route-lookup description NAT Description},
        p_proc      => [ {
						'config' => {
                        	'int_interface' => 'INSIDE',
                            'ext_interface' => 'OUTSIDE',
                            'source_nat' => {
                                'real_src' => 'rs',
                                'mapped_src' => 'ms',
                                'type' => 'static',
                            },
                          	'destination_nat' => {
                            	'mapped_dst' => 'md',
                                'real_dst' => 'rd',
                                'type' => 'static',
                            },
                            'proxy_arp' => 0,
                            'route_lookup' => 1,
                            'description' => 'NAT Description'
                        },
                        'type' => 'nat' }],
        desc        => q{Static Source and Dest NAT with no-proxy-arp, route-lookup & description}
    },
);




my @all_tests = (
    @small_config_items,
    @routes,
    @nat,
);

# + 1 is for the use_ok()
plan tests => 1 + @all_tests; 

use_ok( 'Device::Network::ConfigParser::Cisco::ASA', qw{get_parser parse_config post_process} ) || print "Bail out!\n";

my $parser = get_parser();

# Run all tests
for my $test (@all_tests) {
    my $parsed = parse_config($parser, $test->{test});
    my $post_processed = post_process($parsed);

    is_deeply( $post_processed, $test->{p_proc}, $test->{desc} );
}
    



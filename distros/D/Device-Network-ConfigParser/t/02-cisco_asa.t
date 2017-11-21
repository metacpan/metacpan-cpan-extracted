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

my @objects = (
    {
        test        => q{object network NET_OBJ host 192.0.2.1},
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'NET_OBJ', 'object_type' => 'network', description => '', 'object_value' => 
                                {'ip' => '192.0.2.1', 'type' => 'host'}
                            }
                        ]

                    }],
        desc        => q{Network Host Object}
    },
    {
        test        => q{object network NET_OBJ host 192.0.2.1 description DESC},
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'NET_OBJ', 'object_type' => 'network', description => 'DESC', 'object_value' => 
                                {'ip' => '192.0.2.1', 'type' => 'host'}
                            }
                        ]
                    }],
        desc        => q{Network Host Object with description}
    },
    {
        test        => q{object network NET_OBJ range 192.0.2.0 192.0.2.15},
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'NET_OBJ', 'object_type' => 'network', description => '', 'object_value' => 
                                {'range_start' => '192.0.2.0', range_end => '192.0.2.15', 'type' => 'range'}
                            }
                        ]
                    }],
        desc        => q{Network Range Object}
    },
    {
        test        => q{object network NET_OBJ subnet 192.0.2.0 255.255.255.0}, 
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'NET_OBJ', 'object_type' => 'network', description => '', 'object_value' => 
                                {'network' => '192.0.2.0', netmask => '255.255.255.0', 'type' => 'subnet'}
                            }
                        ]
                    }],
        desc        => q{Network Subnet Object}
    },
    {
        test        => q{object network NET_OBJ fqdn www.test.local}, 
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'NET_OBJ', 'object_type' => 'network', description => '', 'object_value' => 
                                {'fqdn' => 'www.test.local', 'type' => 'fqdn'}
                            }
                        ]
                    }],
        desc        => q{Network FQDN Object}
    },
    {
        test        => q{object network NO_VALUE}, 
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'NO_VALUE', 'object_type' => 'network', description => '', 'object_value' => 
                                {}
                            }
                        ]
                    }],
        desc        => q{Network Object No Values}
    },
    {
        test        => q{object network DESCRIPTION description Desc}, 
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'DESCRIPTION', 'object_type' => 'network', description => 'Desc', 'object_value' => 
                                {}
                            }
                        ]
                    }],
        desc        => q{Network Object Only Description}
    },
    {
        test        => q{object service SVC_OBJ service 6}, 
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'SVC_OBJ', 'object_type' => 'service', description => '', 'object_value' => 
                                    { protocol => '6' }
                            }
                        ]
                    }],
        desc        => q{Service Object Protocol Number}
    },
    {
        test        => q{object service SVC_OBJ service eigrp}, 
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'SVC_OBJ', 'object_type' => 'service', description => '', 'object_value' => 
                                    { protocol => 'eigrp' }
                            }
                        ]
                    }],
        desc        => q{Service Object Protocol Name}
    },
    {
        test        => q{object service SVC_OBJ service tcp source range 0 65535 destination eq 80}, 
        p_proc      => [{ 'type' => 'object', 'config' => [
                            {'name' => 'SVC_OBJ', 'object_type' => 'service', description => '', 'object_value' => 
                                {
                                    protocol => 'tcp',
                                    source => {
                                        port_start => '0',
                                        port_end => '65535',
                                        op => 'range'
                                    },
                                    destination => {
                                        op => 'eq',
                                        port => '80'
                                    }
                                }
                            }
                        ]
                    }],
        desc        => q{Service Object TCP Source and Destination}
    },
);

my @object_groups = (
    {
        test        => q{object-group network OBJ_NAME group-object NET_OBJ},
        p_proc      =>  [{
                            type => 'object-group',
                            config => [
                                {
                                    group_type => 'network',
                                    name => 'OBJ_NAME',
                                    description => '',
                                    group_members => [
                                        { 
                                            type => 'group-object',
                                            group => 'NET_OBJ',
                                        }
                                    ]
                                }
                            ]
                        }],
        desc        => q{Object Group with Group Object}
    },
    {
        test        => q{object-group network OBJ_NAME network-object host 192.0.2.0},
        p_proc      =>  [{
                            type => 'object-group',
                            config => [
                                {
                                    group_type => 'network',
                                    name => 'OBJ_NAME',
                                    description => '',
                                    group_members => [
                                        { 
                                            type => 'host',
                                            ip => '192.0.2.0',
                                        }
                                    ]
                                }
                            ]
                        }],
        desc        => q{Network object group with host}
    },
    {
        test        => q{object-group network OBJ_NAME network-object 192.0.2.0 255.255.255.0},
        p_proc      =>  [{
                            type => 'object-group',
                            config => [
                                {
                                    group_type => 'network',
                                    name => 'OBJ_NAME',
                                    description => '',
                                    group_members => [
                                        { 
                                            type => 'subnet',
                                            network => '192.0.2.0',
                                            netmask => '255.255.255.0'
                                        }
                                    ]
                                }
                            ]
                        }],
        desc        => q{Network object group with subnet network object}
    },
    {
        test        => q{object-group network OBJ_NAME network-object object ANOTHER_OBJECT},
        p_proc      =>  [{
                            type => 'object-group',
                            config => [
                                {
                                    group_type => 'network',
                                    name => 'OBJ_NAME',
                                    description => '',
                                    group_members => [
                                        { 
                                            type => 'object',
                                            object => 'ANOTHER_OBJECT'
                                        }
                                    ]
                                }
                            ]
                        }],
        desc        => q{Network object group network object}
    },
    {
        test        => q{object-group service SVC_OBJ_GROUP
 							description Service Object
 							service-object 16 
							service-object gre 
							service-object tcp source range 0 65535 destination eq https 
							service-object object SVC_OBJ},
        p_proc      =>  [{
                            type => 'object-group',
                            config => [
                                {
                                    group_type => 'service',
                                    name => 'SVC_OBJ_GROUP',
                                    description => 'Service Object',
                                    group_members => [
                                        { 
                                            type => 'service',
                                            protocol => '16',
			                                  	
                                        },
                                        { 
                                            type => 'service',
                                            protocol => 'gre'
                                        },
                                        { 
                                            type => 'service',
                                            protocol => 'tcp',
                                            source => {
                                                op => 'range',
                                                port_start => '0',
                                                port_end => '65535'
                                            },
                                            destination => {
                                                op => 'eq',
                                                port => 'https'
                                            }
                                        },
                                        { 
                                            type => 'service-object',
                                            object => 'SVC_OBJ',
                                        },
                                    ]
                                }
                            ]
                        }],
        desc        => q{Network object group many objects}
    },
    {
        test        => q{object-group service SVC_OBJ_GRP_TCP tcp
                            description Port Object
                            port-object eq https},
        p_proc      =>  [{
                            type => 'object-group',
                            config => [
                                {
                                    group_type => 'service',
                                    name => 'SVC_OBJ_GRP_TCP',
                                    description => 'Port Object',
                                    group_members => [
                                        { 
                                            type => 'port-object',
                                            operator => 'eq',
                                            port => 'https',
                                        },
                                    ]
                                }
                            ]
                        }],
        desc        => q{Network object group port object}
    },
    {
        test        => q{object-group protocol OBJ_GRP_PROTO
                            description Protocol Object
                            protocol-object ip
                            group-object ANOTHER_GROUP},
        p_proc      =>  [{
                            type => 'object-group',
                            config => [
                                {
                                    group_type => 'protocol',
                                    name => 'OBJ_GRP_PROTO',
                                    description => 'Protocol Object',
                                    group_members => [
                                        { 
                                            type => 'protocol-object',
                                            protocol => 'ip',
                                        },
                                        { 
                                            type => 'group',
                                            object => 'ANOTHER_GROUP',
                                        },
                                    ]
                                }
                            ]
                        }],
        desc        => q{Protocol Object Group}
    },
);
        





my @all_tests = (
    @small_config_items,
    @routes,
    @nat,
    @objects,
    @object_groups,
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
    



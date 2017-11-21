package Device::Network::ConfigParser::Cisco::ASA;
# ABSTRACT: Parse Cisco ASA Configuration
our $VERSION = '0.006'; # VERSION

use 5.006;
use strict;
use warnings;
use Modern::Perl;
use Parse::RecDescent;
use Data::Dumper;
use JSON;

use Exporter qw{import};

our @EXPORT_OK = qw{get_parser get_output_drivers parse_config post_process};

=head1 NAME

Device::Network::ConfigParser::Cisco::ASA - parse Cisco ASA configuration.

=head1 VERSION

version 0.006

=head1 SYNOPSIS

This module is intended to be used in conjunction with L<Device::Network::ConfigParser>, however there's nothing stopping it being used on its own.

The module provides subroutines to parse & post-process Cisco ASA configuration, and output the structured data in a number of formats.

=head1 SUBROUTINES

=head2 get_parser

For more information on the subroutine, see L<Device::Network::ConfigParser/"get_parser">.

This module currently recognised the following parts of Cisco ASA configuration:

=over 4

=item * Hostname and domain name

=item * Name aliases

=item * Routes

=item * Access lists

=item * NATs

=item * Objects

=item * Object groups

Any other lines within the file are classified as 'unrecognised'.

=back

=cut

# This function is used with the (?) RecDescent operator, which returns an ARRAYREF.
# If there's an array member, it's returned.
# If not, the empty string is returned.
sub Parse::RecDescent::_zero_or_one {
    my ($array_ref, $action, $return) = @_;

    $return //= '';
    $action //= sub { return $_[0]->[0] }; # By default, return the first member

    scalar @{ $array_ref } ? $action->($array_ref) : $return;
}
    


sub get_parser {
    return new Parse::RecDescent(q{
        <autoaction: { \%item }>
        startrule: config(s) { $item[1] }
        config:
            hostname { $item[1] } |
            domain_name { $item[1] } |
            name { $item[1] } |
            route { $item[1] } |
            acl { $item[1] } |
            nat { $item[1] } |
            object(s) { { type => 'object', config => $item{'object(s)'} } } |
            object_group(s) { { type => 'object-group', config => $item[1] } } |
            unrecognised { $item[1] }

            hostname: 'hostname' m{\w+} { { type => $item{__RULE__}, config => $item{__PATTERN1__} } }
            domain_name: 'domain-name' m{\S+} { 
                { type => $item{__RULE__}, config => $item{__PATTERN1__} } 
            }

            name: 'name' ipv4 name_alias { 
                { type => $item{__RULE__}, config => { ip => $item{ipv4}, alias => $item{name_alias} } } 
            }

            route: 'route' interface network netmask next_hop metric track(?) { 
                {   type => $item{__RULE__}, config => { 
                    interface => $item{interface}, 
                    destination => $item{network}."/".$item{netmask}, 
                    next_hop => $item{next_hop},
                    metric => $item{metric},
                    track_id => @{ $item{'track(?)'} } ? $item{'track(?)'}->[0] : '',
                    }
                }
            }
                network: alias_or_ipv4 { $item[1] }
                next_hop: alias_or_ipv4 { $item[1] }
                metric: m{\d{1,3}} { $item{__PATTERN1__} }
                track: 'track' m{\d{1,3}} { $item{__PATTERN1__} }

            acl: 'access-list' m{\N+} { { type => 'acl', slurp => $item{__PATTERN1__} } }

            nat: 'nat' int_interface ext_interface source_nat destination_nat(?) proxy_arp(?) route_lookup(?) nat_description(?) {
                { type => $item{__RULE__}, config => {
                    int_interface => $item{int_interface},
                    ext_interface => $item{ext_interface},
                    source_nat => $item{source_nat},
                    destination_nat => @{ $item{'destination_nat(?)'} } ? $item{'destination_nat(?)'}->[0] : {},
                    description => @{ $item{'nat_description(?)'} } ? $item{'nat_description(?)'}->[0] : '',
                    proxy_arp => @{ $item{'proxy_arp(?)'} } ? 0 : 1,  
                    route_lookup => scalar(@{ $item{'route_lookup(?)'} }),
                    }
                }
            }
                source_nat: 'source' m{static|dynamic} real_src mapped_src {
                    { type => $item{__PATTERN1__}, real_src => $item{real_src}, mapped_src => $item{mapped_src}, }
                }
                destination_nat: 'destination' m{static|dynamic} mapped_dst real_dst {
                    { type => $item{__PATTERN1__}, mapped_dst => $item{mapped_dst}, real_dst => $item{real_dst}, }
                }
                int_interface: '(' m{\w+} ',' { $item{__PATTERN1__} }
                ext_interface: m{\w+} ')' { $item{__PATTERN1__} }
                real_src: 'any' { $item[1] } | object_name { $item[1] } 
                mapped_src: 'any' { $item[1] } | 'interface' { $item[1] } | object_name { $item[1] } 
                mapped_dst: 'any' { $item[1] } | object_name { $item[1] } 
                real_dst: 'any' { $item[1] } | object_name { $item[1] } 
                nat_description: 'description' m{[ -~]+} { $item{__PATTERN1__} }
                proxy_arp: 'no-proxy-arp' { 1; }
                route_lookup: 'route-lookup' { 1; }

            object: 'object' m{network|service} object_name  <matchrule:$item{__PATTERN1__}_obj_body>(?) description(?) {
                {
                    name => $item{object_name},
                    object_type => $item{__PATTERN1__},
                    object_value => _zero_or_one($item{'$item{__PATTERN1__}_obj_body(?)'}, undef, {}),
                    description => _zero_or_one($item{'description(?)'})
                }
            }

            network_obj_body: 'host' ipv4 { { type => 'host', ip => $item{ipv4} } } | 
                              'range' range { { type => 'range', range_start => $item{range}->[0], range_end => $item{range}->[1] } } | 
                              'subnet' subnet { { type => 'subnet', network => $item{subnet}->[0], netmask => $item{subnet}->[1] } } | 
                              'fqdn' fqdn { { type => 'fqdn', fqdn => $item{fqdn} } } 

            service_obj_body: 
                'service' protocol { $item{protocol} } 

                protocol: 
                    m{\d{1,3}} { { protocol => $item{__PATTERN1__} } } | 
                    m{ah|eigrp|esp|gre|igmp|igrp|ip|ipinip|ipsec|nos|ospf|pcp|pim|pptp|sctp|snp} { { protocol => $item{__PATTERN1__} } } |
                    m{tcp|udp} ('source' port_spec)(?) ('destination' port_spec)(?) {
                        my $source_spec = $item{'_alternation_1_of_production_3_of_rule_protocol(?)'};
                        my $dest_spec = $item{'_alternation_2_of_production_3_of_rule_protocol(?)'};

                        {
                            protocol => $item{__PATTERN1__},
                            source => _zero_or_one($source_spec, sub { $_[0]->[0]->{port_spec} }, {}),
                            destination => _zero_or_one($dest_spec, sub { $_[0]->[0]->{port_spec} }, {}),
                        }
                    }

                    port_spec: 
                        m{eq|gt|lt|neq} m{\w+} { { op => $item{__PATTERN1__}, port => $item{__PATTERN2__} } } |
                        'range' m{\w+} m{\w+} { { op => $item{__STRING1__}, port_start => $item{__PATTERN1__}, port_end => $item{__PATTERN2__} } }

                                            


            object_group: 
                'object-group' m{network|service|protocol} object_name m{(tcp|tcp-udp|udp)?} 
                description(?) <matchrule:$item{__PATTERN1__}_obj_grp_body>(s?) {
                    { 
                        name => $item{object_name},
                        group_type => $item{__PATTERN1__},
                        group_members => $item{'$item{__PATTERN1__}_obj_grp_body(s?)'},
                        description => _zero_or_one($item{'description(?)'}),
                    }
            }
                
                network_obj_grp_body:
                    'group-object' object_name { { type => 'group-object', group => $item{object_name} } } | 
                    'network-object host' ipv4 { { type => 'host', ip => $item{ipv4} } } | 
                    'network-object' subnet { { type => 'subnet', network => $item{subnet}->[0], netmask => $item{subnet}->[1] } } |
                    'network-object object' object_name { { type => 'object', object => $item{object_name} } }


                service_obj_grp_body:
                    port_object { $item{port_object} } | 
                    group_object { $item{group_object} } | 
                    service_object { $item{service_object} } 

                    port_object: 
                        'port-object' 'eq' m{\w+} { 
                            {
                                type => 'port-object',
                                operator => 'eq',  
                                port => $item{__PATTERN1__}
                            }
                        }
                        |
                        'port-object' 'range' m{\w+} m{\w+} {     
                            { 
                                type => 'port-object',
                                operator => 'range',
                                port_start => $item{__PATTERN1__},
                                port_end => $item{__PATTERN2__},
                            }
                        }

                    group_object: 'group-object' object_name { { type => 'group', object => $item{object_name} } }

                    service_object: 
                        'service-object object' object_name { { type => 'service-object', object => $item{object_name} } } |
                        'service-object' protocol { { type => 'service', %{ $item{protocol} } } }

                             

                protocol_obj_grp_body: 
                    group_object { $item{group_object} } | 
                    protocol_object { $item{protocol_object} } 

                    protocol_object: 'protocol-object' m{\w+} { 
                        {
                            type => 'protocol-object',
                            protocol => $item{__PATTERN1__}
                        }
                    }
                    
             


        # Utility definitions, used in many placed
        ipv4: m{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}} { $item{__PATTERN1__} }
        netmask: m{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}} { $item{__PATTERN1__} }
        fqdn: m{[\-\w\.]+} { $item[1] }
        range: ipv4 ipv4 { [$item[1], $item[2]] }
        subnet: ipv4 netmask { [$item[1], $item[2]] }

        description: 'description' m{[ -~]+} { $item{__PATTERN1__} }

        name_alias: m{[!-~]+} { $item{__PATTERN1__} }
        object_name: m{[!-~]+} { $item{__PATTERN1__} }

        interface: m{[!-~]+} { $item{__PATTERN1__} }

        alias_or_ipv4: name_alias { $item[1] } | ipv4 { $item[1] }

        unrecognised: m{\N+} { 
            { type => $item[0], config => $item[1] } 
        }
    });
}

=head2 parse_config

For more information on the subroutine, see L<Device::Network::ConfigParser/"parse_config">.

=cut

sub parse_config {
    my ($parser, $config_contents) = @_;

    #$::RD_TRACE = 1;

    my $parse_tree = $parser->startrule($config_contents);

    return $parse_tree;
}

=head2 post_process

For more information on the subroutine, see L<Device::Network::ConfigParser/"post_process">.

This module does not post-process the data structure.


=cut

sub post_process {
    my ($parsed_config) = @_;

    return $parsed_config;
}

=head2 get_output_drivers

For more information on the subroutine, see L<Device::Network::ConfigParser/"get_output_drivers">.

This module supports the following output drivers:

=over 4

=item * csv - writes the parsed configuration out in CSV format.


=back

=cut

sub get_output_drivers {
    return { 
        csv => \&csv_output_driver,
    };
}


=head2 csv_output_driver

=cut

sub csv_output_driver {
    my ($fh, $filename, $parsed_config) = @_;
    my $csv_type_driver = { 
        interface       => \&_csv_interface_driver,
        static_route    => \&_csv_static_route_driver,
        not_config      => \&_csv_not_config_driver,
    };

    say "=" x 16 . "BEGIN FILE $filename" . "=" x 16;

    TYPE:
    for my $type (keys %{ $parsed_config }) {
        say "-" x 8 . "BEGIN TYPE $type" . "-" x 8;

        defined $csv_type_driver->{$type} ? 
            $csv_type_driver->{$type}->($fh, $parsed_config->{$type}) :
            warn "No CSV output driver for $type\n" and next TYPE;

        say "-" x 8 . "END TYPE $type" . "-" x 8;
    }

    say "-" x 8 . "END FILE $filename" . "-" x 8;
}

sub _csv_interface_driver {
    my ($fh, $interfaces_ref) = @_;

    # Print the CSV schema line
    my @interface_properties = qw{name state vlan ipv4_address ipv4_mask auto_negotiation link_speed mtu comment};
    say $fh join(',', @interface_properties);

    # Interface through the interfaces, extract and print their properties
    for my $interface (@{ $interfaces_ref }) {
        my @properties = @{ $interface }{ @interface_properties };

        # Replace any undef with an empty string
        @properties =  map { defined $_ ? $_ : '' } @properties;
        say $fh join(',', @properties);
    }
}


sub _csv_static_route_driver {
    my ($fh, $static_routes_ref) = @_;

    my @static_route_properties = qw{destination nexthop nexthop_type status};
    say $fh join(',', @static_route_properties);

    for my $route (@{ $static_routes_ref }) {
        my @properties = @{ $route }{ @static_route_properties };

        # Replace any undef with an empty string
        @properties =  map { defined $_ ? $_ : '' } @properties;
        say $fh join(',', @properties);
    }
}


sub _csv_not_config_driver {
    my ($fh, $not_config) = @_;

    for my $config_line (@{ $not_config }) {
        print $fh "$config_line\n";
    }
}


=head1 AUTHOR

Greg Foletta, C<< <greg at foletta.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-checkpoint-configparse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-CheckPoint-ConfigParse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::CheckPoint::ConfigParse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-CheckPoint-ConfigParse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-CheckPoint-ConfigParse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-CheckPoint-ConfigParse>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-CheckPoint-ConfigParse/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Greg Foletta.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Device::CheckPoint::ConfigParse

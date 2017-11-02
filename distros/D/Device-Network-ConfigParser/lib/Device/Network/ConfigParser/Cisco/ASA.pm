package Device::Network::ConfigParser::Cisco::ASA;
# ABSTRACT: Parse Cisco ASA Configuration

use 5.006;
use strict;
use warnings;
use Modern::Perl;
use Parse::RecDescent;
use Data::Dumper;
use JSON;

use Exporter qw{import};

our @EXPORT_OK = qw{get_parser get_output_drivers parse_config post_process};


sub get_parser {
    return new Parse::RecDescent(q{
        <autoaction: { [@item] }>
        startrule: config(s) { $item[1] }
        config:
            hostname { $item[1] } |
            domain_name { $item[1] } |
            name { $item[1] } |
            route { $item[1] } |
            acl { $item[1] } |
            nat { $item[1] } |
            object { $item[1] } |
            object_group { $item[1] } |
            not_config { $item[1] }

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
                #use Data::Dumper;
                #print STDERR Dumper \%item;
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

                object: 'object' m{network|service} object_name <matchrule:$item{__PATTERN1__}_obj_body>(0..2) {
                    #use Data::Dumper;
                    #print Dumper \%item;
                    { type => 'object', config => {
                        name => $item{object_name},
                        obj_type => $item{__PATTERN1__},
                        obj_value => $item{'$item{__PATTERN1__}_obj_body(0..2)'} 
                        }
                    }
                }

                network_obj_body: 'host' ipv4 { { type => 'host', ip => $item{ipv4} } } | 
                                  'range' range { { type => 'range', range_start => $item{range}->[0], range_end => $item{range}->[1] } } | 
                                  'subnet' subnet { { type => 'subnet', network => $item{subnet}->[0], netmask => $item{subnet}->[1] } } | 
                                  'fqdn' fqdn { { type => 'fqdn', fqdn => $item{fqdn} } } |
                                  description { { type => 'description', description => $item{description} } }

                service_obj_body: 'service' protocol description(?) { $item{protocol} } | 

                                  protocol: m{\d{1,3}} { protocol => $item{__PATTERN1__} } | 
                                            tcp_udp { $item[1] } |
                                            m{ah|eigrp|esp|gre|igmp|igrp|ip|ipinip|ipsec|nos|ospf|pcp|pim|pptp|sctp|snp} { { protocol => $item{__PATTERN1__} } }
                                            description { type => 'description', description => $item{description} }
                                            
                                tcp_udp: m{tcp|udp} 'destination' m{eq|gt|lt|neq|range} m{[\w-]+} { 
                                    { protocol => $item{__PATTERN1__}, destination => { op => $item{__PATTERN2__}, port => $item{__PATTERN3__} } }
                                }




                object_group: 'object-group' m{network|service|protocol} object_name m{(tcp|tcp-udp|udp)?} <matchrule:$item{__PATTERN1__}_obj_grp_body>(s?) {
                #use Data::Dumper;
                #print Dumper \%item;
                    { 
                        type => $item{__RULE__}, 
                        name => $item{object_name},
                        obj_grp_type => $item{__PATTERN1__},
                        obj_grp_value => $item{'$item{__PATTERN1__}_obj_grp_body(s?)'},
                    }
                }
                    
                    network_obj_grp_body:   'group-object' object_name { { type => 'group-object', group => $item{object_name} } } | 
                                            'network-object host' ipv4 { { type => 'host', host => $item{ipv4} } } | 
                                            'network-object' subnet { { type => 'subnet', network => $item{subnet}->[0], netmask => $item{subnet}->[1] } } |
                                            description { { type => $item{__RULE__}, description => $item{description} } }


                    service_obj_grp_body:   port_object { $item{port_object} } | 
                                            group_object { $item{group_object} } | 
                                            service_object { $item{service_object} } |
                                            description { { description => $item{description} } }

                        group_object: 'group-object' object_name { { type => 'group', object => $item{object_name} } }
                        port_object: 'port-object' m{eq|range} m{\N+} { 
                            { 
                                type => 'port', 
                                op => $item{__PATTERN1__},
                                value => $item{__PATTERN2__},
                            }
                        }
                        service_object: 'service-object' m{\N+} { { type => 'service', slurp => $item{__PATTERN1__} } }
                                 

                    protocol_obj_grp_body: 'protocol' m{\N+} { { slurp => $item{__PATTERN1__} } }

                        
                                      
                    
                    
             


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

        not_config: m{\N+}i { 
            { type => $item[0], config => $item[1] } 
        }
    });
}


sub parse_config {
    my ($parser, $config_contents) = @_;

    #$::RD_TRACE = 1;
    #$::RD_HINT = 1;

    my $parse_tree = $parser->startrule($config_contents);

    return $parse_tree;
}



sub get_output_drivers {
    return { 
        csv => \&csv_output_driver,
        json => \&json_output_driver,
    };
}


sub post_process {
    my ($parsed_config) = @_;

    return $parsed_config;
}



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






sub json_output_driver {
    my ($fh, $filename, $parsed_config) = @_;

    print encode_json($parsed_config);
}


1; # End of Device::CheckPoint::ConfigParse

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Network::ConfigParser::Cisco::ASA - Parse Cisco ASA Configuration

=head1 VERSION

version 0.004

=head1 SYNOPSIS

=head1 NAME

Device::Network::ConfigParser::Cisco::ASA

=head1 VERSION

# VERSION

=head1 SUBROUTINES

=head2 get_parser

=head2 parse_config

=head2 get_output_drivers

Returns a hash of the output driver subs keyed on the --output command line argument

=head2 post_process

=head2 csv_output_driver

=head2 json_output_driver

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

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

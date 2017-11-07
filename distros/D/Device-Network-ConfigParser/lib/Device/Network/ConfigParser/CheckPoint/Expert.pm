package Device::Network::ConfigParser::CheckPoint::Expert;
# ABSTRACT: Parse expert CheckPoint expert mode output.
our $VERSION = '0.005'; # VERSION

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

Device::Network::ConfigParser::CheckPoint::Expert - parse CheckPoint expert mode output.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

This module is intended to be used in conjunction with L<Device::Network::ConfigParser>, however there's nothing stopping it being used on its own.

The module provides subroutines to parse & post-process CheckPoint Expoert mode output. 

=head1 SUBROUTINES

=head2 get_parser

For more information on the subroutine, see L<Device::Network::ConfigParser/"get_parser">.

Thos module currently recognised the following output:

=over 4

=item * 'ip route' output

=item * 'ifconfig' output

=back

=cut

sub get_parser {
    return new Parse::RecDescent(q{
        <autoaction: { [@item] }>
        startrule: config_line(s) { $item[1] }
        config_line: ip_route(s) { { ip_route => $item{'ip_route(s)'} } } |
                     ifconfig(s) { { ifconfig => $item{'ifconfig(s)'} } } |
                     not_parsed { $item[1] }

            ip_route: destination nexthop_ip(?) device proto(?) scope(?) source(?) metric(?) {
                {
                    destination => $item{destination},
                    next_hop => $item{'nexthop_ip(?)'},
                    device => $item{device},
                    proto => $item{proto},
                    scope => $item{'scope(?)'},
                    source => $item{'source(?)'},
                    metric => $item{'metric(?))'}
                }
            }
                
                destination: ipv4 cidr { { network => $item{ipv4}, cidr => $item{cidr} } } | 'default' { { network => '0.0.0.0', cidr => '0' } }
                nexthop_ip: 'via' ipv4 { $item{ipv4} }
                device: 'dev' m{[-\w]+} { $item{__PATTERN1__} }
                proto: 'proto' m{\w+} { $item{__PATTERN1__} }
                scope: 'scope' m{\w+} { $item{__PATTERN1__} }
                source: 'src' ipv4 { $item{ipv4} }
                metric: 'metric' m{\d+} { $item{__PATTERN1__} }

#  inet6(?)

            ifconfig: interface encap hw_addr(?) inet(?) inet6(s?) flag(s) mtu if_metric rx_stats tx_stats rx_bytes tx_bytes {
                {
                    interface => $item{interface},
                    encapsulation => $item{encap},
                    hw_addr => $item{'hw_addr(?)'},
                    inet => $item{'inet(?)'},
                    inet6 => $item{'inet6(s?)'},
                    flags => $item{'flag(s)'},
                    mtu => $item{mtu},
                    metric => $item{if_metric},
                    rx_stats => $item{rx_stats},
                    tx_stats => $item{tx_stats},
                    rx_bytes => $item{rx_bytes},
                    tx_bytes => $item{tx_bytes},
                }
            }

                interface: m{[-\w]+} { $item{__PATTERN1__} }
                encap: 'Link encap:' m{Ethernet|Local Loopback} { $item{__PATTERN1__} }
                hw_addr: 'HWaddr' m{[0-9a-f:]+} { $item{__PATTERN1__} }
                inet: inet_addr inet_bcast(?) inet_mask {
                    {
                        address => $item{inet_addr},
                        mask => $item{inet_mask},
                        broadcast => $item{'inet_bcast(?)'}
                    }
                }
                    inet_addr: 'inet addr:' ipv4 { $item{ipv4} }
                    inet_bcast: 'Bcast:' ipv4 { $item{ipv4} }
                    inet_mask: 'Mask:' netmask { $item{netmask} }
                inet6: inet6_addr inet6_mask inet6_scope {
                    {
                        address => $item{inet6_addr},
                        mask => $item{inet6_mask},
                        scope => $item{inet6_scope}
                    }
                }
                    inet6_addr: 'inet6 addr:' ipv6 { $item{ipv6} }
                    inet6_mask: '/' m{\d{1,3}} { $item{__PATTERN1__} }
                    inet6_scope: 'Scope:' m{\w+} { $item{__PATTERN1__} }

                flag: m{UP|BROADCAST|RUNNING|MULTICAST|LOOPBACK} { $item{__PATTERN1__} }
                mtu: 'MTU:' m{\d+} { $item{__PATTERN1__} }
                if_metric: 'Metric:' m{\d+} { $item{__PATTERN1__} }
                rx_stats: 'RX packets:' m{\d+} 'errors:' m{\d+} 'dropped:' m{\d+} 'overruns:' m{\d+} 'frame:' m{\d+} {
                    {
                        packets => $item{__PATTERN1__},
                        errors => $item{__PATTERN2__},
                        dropped => $item{__PATTERN3__},
                        overruns => $item{__PATTERN4__},
                        frame => $item{__PATTERN5__},
                    }
                }
                tx_stats: 'TX packets:' m{\d+} 'errors:' m{\d+} 'dropped:' m{\d+} 'overruns:' m{\d+} 'carrier:' m{\d+} 'collisions:' m{\d+} 'txqueuelen:' m{\d+}{
                    {
                        packets => $item{__PATTERN1__},
                        errors => $item{__PATTERN2__},
                        dropped => $item{__PATTERN3__},
                        overruns => $item{__PATTERN4__},
                        carrier => $item{__PATTERN5__},
                        collisions => $item{__PATTERN5__},
                        txqueuelen => $item{__PATTERN5__},
                    }
                }
                rx_bytes: 'RX bytes:' m{\d+} m{\(\d{1,}\.\d \w{1,2}\)} { $item{__PATTERN1__} } 
                tx_bytes: 'TX bytes:' m{\d+} m{\(\d{1,}\.\d \w{1,2}\)} { $item{__PATTERN1__} } 


        not_parsed: m{\N+} { { type => $item{__RULE__}, line => $item{__PATTERN1__} } }



        ipv4: m{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}} { $item{__PATTERN1__} }
        netmask: m{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}} { $item{__PATTERN1__} }
        ipv6: m{[0-9a-f:]+} { $item{__PATTERN1__} }
        cidr: '/' m{\d{1,2}} { $item{__PATTERN1__} }
        });
}


=head2 parse_config

For more information on the subroutine, see L<Device::Network::ConfigParser/"parse_config">.

=cut

sub parse_config {
    my ($parser, $config_contents) = @_;

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

=item * json - writes the parsed configuration out as JSON.

=back

=cut

sub get_output_drivers {
    return { 
        csv => \&csv_output_driver,
        json => \&json_output_driver,
    };
}


=head2 csv_output_driver

=cut

sub csv_output_driver {
    my ($fh, $filename, $parsed_config) = @_;
    my $csv_type_driver = { 
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

sub _csv_not_config_driver {
    my ($fh, $not_config) = @_;

    for my $config_line (@{ $not_config }) {
        print $fh "$config_line\n";
    }
}





=head2 json_output_driver

=cut

sub json_output_driver {
    my ($fh, $filename, $parsed_config) = @_;

    print encode_json($parsed_config);
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

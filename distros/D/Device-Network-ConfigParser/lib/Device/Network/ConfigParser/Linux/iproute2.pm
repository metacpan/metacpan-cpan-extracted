package Device::Network::ConfigParser::Linux::iproute2;
# ABSTRACT: Parse output from utilities associated with the iproute2 package
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

Device::Network::ConfigParser::Linux::iproute2 - parse output from utilities associated with the iproute2 package.

=head1 VERSION

version 0.006

=head1 SYNOPSIS

This module is intended to be used in conjunction with L<Device::Network::ConfigParser>, however there's nothing stopping it being used on its own.

=head1 SUBROUTINES

=head2 get_parser

For more information on the subroutine, see L<Device::Network::ConfigParser/"get_parser">.

Thos module currently recognised the following output:

=over 4

=item * 'ip route' output

=back

=cut

sub get_parser {
    return new Parse::RecDescent(q{
        <autoaction: { [@item] }>
        startrule: config_line(s) { $item[1] }
        config_line: ip_route(s) { { ip_route => $item{'ip_route(s)'} } } |
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

This module does not export any output drivers.

=cut

sub get_output_drivers {
    return { 
    };
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

package Device::Network::ConfigParser::CheckPoint::Gaia;
# ABSTRACT: Parse CheckPoint Configuration
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

Device::Network::ConfigParser::CheckPoint::Gaia - parse CheckPoint Gaia configuration.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

This module is intended to be used in conjunction with L<Device::Network::ConfigParser>, however there's nothing stopping it being used on its own.

The module provides subroutines to parse & post-process CheckPoint Gaia configuration, and output the structured data in a number of formats.

=head1 SUBROUTINES

=head2 get_parser

For more information on the subroutine, see L<Device::Network::ConfigParser/"get_parser">.

This module currently parses the following sections of Gaia config:

=over 4

=item * Static routes

=item * Interface configuration

=back

Any other lines within the file are classified as 'unrecognised'.

=cut

sub get_parser {
    return new Parse::RecDescent(q{
        <autoaction: { [@item] }>
        startrule: config_line(s) { $item[1] }
        config_line:
            interface { $item[1] } |
            static_route { $item[1] } |
            unrecognised { $item[1] }

        static_route: 'set static-route' destination (nexthop | comment) { { type => $item[0], config => { @{ $item[2] }, @{ $item[3]->[1] } } } }
            destination: m{((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{2})|default)} { [$item[0], $item[1]] }
            nexthop: 'nexthop' (nexthop_blackhole | nexthop_reject | nexthop_address | nexthop_interface) { [@{$item[2]->[1]}] }
            nexthop_blackhole: 'blackhole' { ['nexthop_type', $item[1]] }
            nexthop_reject: 'reject' { ['nexthop_type', $item[1]] }
            nexthop_address: 'gateway address' ipv4 m{on|off} { [nexthop_type => 'address', nexthop => $item[2]->[1], status => $item[3]] }
            nexthop_interface: 'gateway logical' interface_name m{on|off} { [nexthop_type => 'interface', nexthop => $item[2]->[1], status => $item[3]] }
            comment: 'comment' m{"[\w\s]+"} { [$item[0], $item[2]] }

        interface: 
            'set interface' interface_name (ipv4_address_mask | vlan | state | comment | mtu | auto_negotiation | link_speed)
            { { type => $item[0], config => { name => $item[2]->[1], %{ $item[3]->[1] } } } }

            ipv4_address_mask: ipv4_address ipv4_mask { $return = { @{$item[1]}, @{$item[2]}} }
            ipv4_address: 'ipv4-address' ipv4 { [$item[0], $item[2]->[1]] }
            ipv4_mask: 'mask-length' m{\d+} { [$item[0], $item[2]] }

            vlan: 'vlan' m{\d+} { $return = { $item[0], $item[2] } }
            state: 'state' m{\S+} { $return = { $item[0], $item[2] } }
            comment: 'comments' m{"[\w\s]+"} { $return = { $item[0], $item[2] } }
            mtu: 'mtu' m{\d+} { $return = { $item[0], $item[2] } }
            auto_negotiation: 'auto-negotiation' m{\S+} { $return = { $item[0], $item[2] } }
            link_speed: 'link-speed' m{\S+} { $return = { $item[0], $item[2] } }

        # Utility definitions
        ipv4: m{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}} 
        interface_name: m{\S+} 

        unrecognised: m{\N+} 
        { { type => $item[0], config => $item[1] } }
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

The C<post_process()> subroutine consolidates configuration spread out over multiple lines.

=cut

sub post_process {
    my ($parsed_config) = @_;
    my %aggregation = ();
    my %post_processed_config;

    # For each 'type' of config, (e.g. interface config), the aggregator key we're using to aggregate the separate
    # config lines together into a single hash.
    my $aggregator_keys_for = {
        interface       => q{$config_entry->{config}->{name}},
        static_route    => q{$config_entry->{config}->{destination}},
    };

    # Go through each config entry (which was originally each line of config. If there's an aggregate key defined, 
    # aggregate on the 'type' and then this 'key'. 
    #
    # If not, then just push it to the post processed hash.
    for my $config_entry (@{ $parsed_config }) {
        if (exists $aggregator_keys_for->{ $config_entry->{type} }) {
            my $aggregate_key = eval $aggregator_keys_for->{ $config_entry->{type} };
            @{ $aggregation{ $config_entry->{type} }{ $aggregate_key } }{ keys %{ $config_entry->{config} } } = values %{ $config_entry->{config} };
        } else {
            push @{ $post_processed_config{ $config_entry->{type} } }, $config_entry->{config};
        }
    }

    # It's of the form $aggregation{type}{key} = { #interface into }; but the key is implicitly part of the hash it points to.
    # Turn the hash of hash of hashes into a hash of array of hashes ( $aggregation{type} = [ { #interface info } ];
    for my $config_type (keys %aggregation) {
        $aggregation{ $config_type } = [ values %{ $aggregation{ $config_type } } ];
    }

    @post_processed_config{ keys %aggregation } = values %aggregation;

    return \%post_processed_config;
}

=head2 get_output_drivers

For more information on the subroutine, see L<Device::Network::ConfigParser/"get_output_drivers">.

Currently supported output drivers are:

=over 4

=item * csv - writes the parsed configuration out in CSV format.

=item * json - writes the parsed configuration out as JSON.

=back

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

package Device::Network::ConfigParser;
# ABSTRACT: A harness for parsing network device configuration.


use 5.006;
use strict;
use warnings;
use Modern::Perl;
use Getopt::Long;
use Pod::Usage;
use Perl6::Slurp;
use Module::Load;
use Data::Dumper;
use Scalar::Util qw{reftype};


use Exporter qw{import};

our @EXPORT_OK = qw{app};


sub app {
    local @ARGV = @_;
    my %args;

    GetOptions(
        "vendor=s"  => \$args{vendor},
        "type=s"    => \$args{type},
        "format=s"  => \$args{format},
        "output=s"  => \$args{output}
    ) or pod2usage(2);

    # Set the defaults
    $args{vendor} //= 'CheckPoint';
    $args{type}   //= 'Gaia';
    $args{format} //= 'raw';
    $args{output} //= '-';      # STDOUT


    # Load the module specified by the command line parameters
    my $parser_module_name = "Device::Network::ConfigParser::$args{vendor}::$args{type}";
    load $parser_module_name, qw{get_parser get_output_drivers parse_config post_process};

    # Check the exports
    if (!defined &get_parser ||
        !defined &get_output_drivers ||
        !defined &parse_config ||
        !defined &post_process) {
        die "$parser_module_name does not export all required subroutines\n";
    }

    # Retrieve the parser and the output drivers from the module. If 'raw' doesn't exist,
    # it's populated with the default sub from this package.
    # The active driver is then selected for use.
    my $parser = get_parser();
    my $output_drivers = get_output_drivers();
    $output_drivers->{raw} //= \&_default_raw_output_driver;
    my $active_output_driver = $output_drivers->{ $args{format} };

    if (!defined $active_output_driver || reftype $active_output_driver ne 'CODE' ) {
        die "'$args{format}' is not a valid output driver for $parser_module_name\n";
    }

    # If there are no files specified, we slurp from STDIN
    push @ARGV, \*STDIN if !@ARGV;  

    for my $config_filename (@ARGV) {
        # Read in the configuration
        my $raw_config = slurp $config_filename;

        # Change the name to something sensible so it isn't stringified to something like 'GLOB(0x17c7350)'
        $config_filename = 'STDIN' if reftype($config_filename) && reftype($config_filename) eq 'GLOB';

        # Call the parser imported from the module.
        my $parsed_config = parse_config($parser, $raw_config); 

        # Perform any post-processing.
        my $post_processed_config = post_process($parsed_config); 

        # Open the file, which could be STDOUT
        my $fh;
        if ($args{output} eq '-') {
            local *STDOUT;
            $fh = \*STDOUT;
        } else {
            # Replace the placeholder with the filename
            my ($outfile) = $args{output} =~ s{%in_file%}{$config_filename}rxms;
            open($fh, ">>:encoding(UTF-8)", $outfile) or die "Unable to open output file '$outfile': $!\n";
        }

        # Call the output driver.
        $active_output_driver->($fh, $config_filename, $post_processed_config);

        close($fh) unless $args{output} eq '-';
    } 

    return 0;
}


sub _default_raw_output_driver {
    my ($fh, $filename, $parsed_config) = @_;
    print $fh Dumper($parsed_config);
}


1; # End of Device::Network::ConfigParser

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Network::ConfigParser - A harness for parsing network device configuration.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

Device::Network::ConfigParser is a harness for parsing network device configuration. It exports a single subroutine - C<app()> - which takes command line arguments and runs the harness. This module is used by the C<ncp> command line utility. For information on how to use the command line utility, refer to the L<ncp>, or following installation type C<perldoc ncp> at the command line.

The harness supports specific parsing modules by:

=over 4

=item * Dynamically loading a specific parsing module based on command line arguments.

=item * Slurping in the device configuration from STDIN or from a number of files.

=item * Opening the required output filehandles.

=back

=head1 DEVELOPING MODULES

Parsing modules exist within the C<Device::Network::ConfigParser::> namespace. For a I<vendor> and I<type> of device, the module is defined as C<Device::Network::ConfigParser::vendor::type>.

The harness takes care of parsing the command line arguments, opening files (or STDIN/STDOUT) and slurping in their contents. It calls specified subroutines exported by the specified parsing module. Any module must export the following subroutines:

=over 4

=item * B<get_parser>

This sub receives no arguments, and must return a reference to an object or another subroutine that parses the configuration. This is most likely going to be a Parse::RecDescent object, but you're not limited to this.

=item * B<parse_config>

This sub receives the reference returned by the C<get_parser> sub, and the full contents of a file specified on the command line. It should return a reference a data structure that represents the parsed configuration.

=item * B<post_process>

This sub receives the reference to the data structure returned by C<parse_config>. It allows for some post-processing of the data structure. If no processing is required, it can be defined as C<sub post_process { return @_; }>.

=item * B<get_output_drivers>

This sub receives no arguments, and must return a HASHREF of subroutines used to output the parsed configurationm keyed on the command line argument. For example the sub may return:

    {
        csv => \&csv_output_driver,
    }  

If the user specified C<--output csv> as a command line argument, the C<csv_output_driver> would be called. When called, each output driver receives a filehandle to write the output to, the name of the file, and the post-processed data structure.

There is a default 'raw' driver always present, which uses Data::Dumper to serialise the structure. The module may return its own 'raw' driver which will override this default.

=back

=head1 SUBROUTINES

=head2 app 

The C<app> subroutine in general takes C<@ARGV> (although it could be any list) and runs the harness.

=head1 AUTHOR

Greg Foletta, C<< <greg at foletta.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-network-configparser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Network-ConfigParser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Network::ConfigParser

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Network-ConfigParser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-Network-ConfigParser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-Network-ConfigParser>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-Network-ConfigParser/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Greg Foletta.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Pod::Usage;
use Getopt::Long;

use Flickr::Tools::Cameras;
use 5.010;

our $VERSION = '1.22';

my $cli_args = {};

GetOptions (
    $cli_args,
    'config=s',
    'brand=s',
    'list_brands',
    'help',
    'man',
    'usage',
);

if (   $cli_args->{'help'}
    || $cli_args->{'usage'}
    || $cli_args->{'man'}
    || !$cli_args->{'config'} )
{

    pod2usage( { -verbose => 2 } );

}

my $tool =
  Flickr::Tools::Cameras->new( { config_file => $cli_args->{config} } );

if ( $tool->connects ) {

    my $makers = $tool->getBrands;

    if ( $cli_args->{list_brands} ) {

        print Dumper($makers);

    }

    if ( defined( $makers->{ $cli_args->{brand} } )
        && !$cli_args->{list_brands} )
    {

        my $models = $tool->getBrandModels( { Brand =>, $cli_args->{brand} } );
        print Dumper($models);

    }
    else {

        if ( !$cli_args->{list_brands} ) {

            say 'The brand: ', $cli_args->{brand}, ' was not found.';

        }

    }
}
else {

    say 'The tool failed to connect';

}

exit;

__END__

=pod

=head1 NAME

flickr_cameras.pl - example use of Flickr::Tools::Cameras to query Flickr.

=head1 USAGE

C<flickr_cameras.pl --config=Config-File_to_use [--list_brands  --brand=Brand_name]>

=head1 DESCRIPTION

This example just uses the Flickr::Tools::Cameras module to
display information about cameras and camera brands that
Flickr knows about.

=head1 REQUIRED ARGUMENTS

=over

=item  B<--config> points the stored Flickr config file

=back

=head1 OPTIONS

=over

=item  B<--list_brands>   Data::Dumper dump of the brands Flickr knows about.

B< >

=item  B<--brand=Brand_name>  Data::Dumper dump of the models of Brand_name
       cameras the Flickr knows about.

B< >

=item  B<--help> as expected

=item  B<--usage>

=item  B<--man>

=back

=head1 CONFIGURATION

Needs a storable configuration file built using the Flickr::API
configuration scripts.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

Not in an example script

=head1 EXIT STATUS

Not set to any particular value

=head1 BUGS AND LIMITATIONS

Example script, and is very limited.

=head1 AUTHOR

Louis B. Moore C<< <lbmoore@cpan.org> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015, Louis B. Moore C<< <lbmoore@cpan.org> >>.


This program is released under the Artistic License 2.0 by The Perl Foundation.


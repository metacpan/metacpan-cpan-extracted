#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Pod::Usage;
use Getopt::Long;

use Flickr::Tools::Reflection;
use 5.010;

our $VERSION = '1.22';

my $cli_args = {};

GetOptions (
    $cli_args,
    'config=s',
    'method=s',
    'list_methods',
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
  Flickr::Tools::Reflection->new( { config_file => $cli_args->{config} } );

if ( $tool->connects ) {

    my $methods = $tool->getMethods;

    if ( $cli_args->{list_methods} ) {

        print Dumper($methods);

    }

    if ( defined( $methods->{ $cli_args->{method} } )
        && !$cli_args->{list_methods} )
    {

        my $method = $tool->getMethod( { Method =>, $cli_args->{method} } );
        print Dumper($method);

    }
    else {

        if ( !$cli_args->{list_methods} ) {

            say 'The method: ', $cli_args->{method}, ' was not found.';

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

flickr_reflection.pl - example use of Flickr::Tools::Reflection to query Flickr.

=head1 USAGE

C<flickr_reflection.pl --config=Config-File_to_use [--list_methods  --method=Method_name]>

=head1 DESCRIPTION

This example just uses the Flickr::Tools::Reflection module to
display information about Flickr's methods.


=head1 REQUIRED ARGUMENTS

=over

=item  B<--config> points the stored Flickr config file

=back

=head1 OPTIONS

=over

=item  B<--list_methods>   Data::Dumper dump of the methods Flickr knows about.


=item  B<--method=Method_name>  Data::Dumper dump of the details of the 
       Method_name method the Flickr knows about.


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


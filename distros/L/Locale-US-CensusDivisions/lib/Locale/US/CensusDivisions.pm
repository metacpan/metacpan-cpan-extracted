package Locale::US::CensusDivisions;

use strict;
use warnings;

use Exporter;
use Carp qw(croak);

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( state2division );

# ABSTRACT: Locale::US::CensusDivisions - module to get US Census Divisions
our $VERSION = '1.1.0'; # VERSION 1.1.0

=pod

=encoding utf8

=head1 NAME

    Locale::US::CensusDivisions - Module to provide Census Bureau Divisions

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Locale::US::CensusDivisions qw(state2division);

    my $division = state2division('TX');

    print "The division for that state is $division \n";

=head1 DESCRIPTION

    This module takes a US state abbreviation and returns the division number associated with that state.

=head1 METHODS

=head2 state2division

    See Synopsis

=head1 BUGS AND LIMITATIONS

This module currently only supports US states and District of Columbia.
It does not support US territories.

=head1 AUTHOR

Daniel Culver, C<< perlsufi@cpan.org >>

=head1 ACKNOWLEDGEMENTS

Wikipedia L<Census Bureau Divisions|https://en.wikipedia.org/wiki/List_of_regions_of_the_United_States#Census_Bureau-designated_regions_and_divisions>

L<HostGator|http://www.hostgator.com>

=head1 CONTRIBUTORS

William Seymour

Doug Schrag

Robert Stone

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

our %divisions = (
    1 => [ 'CT', 'ME', 'MA', 'NH', 'RI', 'VT' ],
    2 => [ 'NJ', 'NY', 'PA' ],
    3 => [ 'IL', 'IN', 'WI', 'MI', 'OH' ],
    4 => [ 'MN', 'KS', 'IA', 'MO', 'NE', 'ND', 'SD' ],
    5 => [ 'DE', 'FL', 'GA', 'MD', 'NC', 'SC', 'VA', 'DC', 'WV' ],
    6 => [ 'AL', 'KY', 'MS', 'TN' ],
    7 => [ 'AR', 'LA', 'OK', 'TX' ],
    8 => [ 'AZ', 'CO', 'ID', 'MT', 'NV', 'NM', 'UT', 'WY', ],
    9 => [ 'CA', 'WA', 'HI', 'OR', 'AK' ],
);

sub state2division {
    my $code = shift
      || croak 'state2division requires a state abbreviation string';

    for my $division ( keys %divisions ) {
        if ( grep { $code eq $_ } @{ $divisions{$division} } ) {
            return $division;
        }
    }

    croak "The state abbreviation ($code) you provided was not found";
}

1;

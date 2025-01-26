package Geo::Location::IP::Model::City;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::City;

our $VERSION = 0.001;

use Geo::Location::IP::Record::City;
use Geo::Location::IP::Record::Continent;
use Geo::Location::IP::Record::Country;
use Geo::Location::IP::Record::Location;
use Geo::Location::IP::Record::MaxMind;
use Geo::Location::IP::Record::Postal;
use Geo::Location::IP::Record::RepresentedCountry;
use Geo::Location::IP::Record::Subdivision;
use Geo::Location::IP::Record::Traits;

field $city :reader;
field $continent :reader;
field $country :reader;
field $location :reader;
field $maxmind :reader;
field $postal :reader;
field $registered_country :reader;
field $represented_country :reader;
field $subdivisions;
field $traits :reader;

method most_specific_subdivision () {
    if (@{$subdivisions} > 0) {
        return $subdivisions->[-1];
    }
    return Geo::Location::IP::Record::Subdivision->new(
        names   => {},
        locales => [],
    );
}

method subdivisions () {
    return @{$subdivisions};
}

#<<<
ADJUST :params (:$raw = {}, :$ip_address = undef, :$locales = undef) {
    if (!defined $locales) {
        $locales = ['en'];
    }

    $city = Geo::Location::IP::Record::City->_from_hash(
        $raw->{city} // {},
        $locales
    );

    $continent = Geo::Location::IP::Record::Continent->_from_hash(
        $raw->{continent} // {},
        $locales
    );

    $country = Geo::Location::IP::Record::Country->_from_hash(
        $raw->{country} // {},
        $locales
    );

    $location = Geo::Location::IP::Record::Location->_from_hash(
        $raw->{location} // {}
    );

    $maxmind = Geo::Location::IP::Record::MaxMind->_from_hash(
        $raw->{maxmind} // {}
    );

    $postal = Geo::Location::IP::Record::Postal->_from_hash(
        $raw->{postal} // {}
    );

    $registered_country = Geo::Location::IP::Record::Country->_from_hash(
        $raw->{registered_country} // {},
        $locales
    );

    $represented_country
        = Geo::Location::IP::Record::RepresentedCountry->_from_hash(
        $raw->{represented_country} // {},
        $locales
    );

    my @subdivisions = map {
        Geo::Location::IP::Record::Subdivision->_from_hash($_, $locales)
    } @{$raw->{subdivisions} // []};
    $subdivisions = \@subdivisions;

    $traits = Geo::Location::IP::Record::Traits->_from_hash(
        $raw->{traits} // {},
        $ip_address
    );
}
#>>>

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::City - Records associated with a city

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file    => '/path/to/City.mmdb',
    locales => ['de', 'en'],
  );
  eval {
    my $city_model = $reader->city(ip => '1.2.3.4');
    my $city       = $city_model->city;
    my $country    = $city_model->country;
    printf "%s in %s\n", $city->name, $country->name;
  };

=head1 DESCRIPTION

This class contains records from an IP address query in a city database.

=head1 SUBROUTINES/METHODS

=head2 new

  my $city_model = Geo::Location::IP::Model::City->new(
    raw => {
        city                => {names    => {en => 'Berlin'}},
        continent           => {names    => {en => 'Europe'}},
        country             => {names    => {en => 'Germany'}},
        location            => {latitude => 52.52, longitude => 13.41},
        maxmind             => {queries_remaining => 9999},
        registered_country  => {names    => {en => 'Germany'}},
        represented_country => {
          names => {en => 'United States'},
          type  => 'military',
        },
        subdivisions => [
          {names => {en => 'Berlin'}, iso_code => 'BE'},
        ],
        traits => {domain => 'example.com'},
    },
    ip_address => $ip_address,
    locales    => ['en'],
  );

Creates a new object.

All records may contain undefined values.

=head2 city

  my $city = $city_model->city;

Returns a L<Geo::Location::IP::Record::City> object.

=head2 continent

  my $continent = $city_model->continent;

Returns a L<Geo::Location::IP::Record::Continent> object.

=head2 country

  my $country = $city_model->country;

Returns a L<Geo::Location::IP::Record::Country> object.

=head2 location

  my $location = $city_model->location;

Returns a L<Geo::Location::IP::Record::Location> object.

=head2 maxmind

  my $maxmind = $city_model->maxmind;

Returns a L<Geo::Location::IP::Record::MaxMind> object.

=head2 postal

  my $postal = $city_model->posal;

Returns a L<Geo::Location::IP::Record::Postal> object.

=head2 registered_country

  my $country = $city_model->registered_country;

Returns a L<Geo::Location::IP::Record::Country> object for the country where
the ISP registered the network.

=head2 represented_country

  my $country = $city_model->represented_country;

Returns a L<Geo::Location::IP::Record::RepresentedCountry> for the country
represented by the users of the IP address.  For example, the country
represented by an overseas military base.

=head2 subdivisions

  my @subdivisions = $city_model->subdivisions;

Returns an array of L<Geo::Location::IP::Record::Subdivision> objects.
Examples of subdivisions are federal states, counties and provinces.

=head2 most_specific_subdivision

  my $subdivision = $city_model->most_specific_subdivision;

Returns a single L<Geo::Location::IP::Record::Subdivision> object.  If there
aren't any subdivisions, an object with undefined values is returned.

=head2 traits

  my $traits = $city_model->traits;

Returns a L<Geo::Location::IP::Record::Traits> object with various details
about the queried IP address.

=for Pod::Coverage DOES META

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

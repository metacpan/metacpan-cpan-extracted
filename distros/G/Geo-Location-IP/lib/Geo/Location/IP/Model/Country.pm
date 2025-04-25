package Geo::Location::IP::Model::Country;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::Country;

our $VERSION = 0.004;

use Geo::Location::IP::Record::Continent;
use Geo::Location::IP::Record::Country;
use Geo::Location::IP::Record::MaxMind;
use Geo::Location::IP::Record::RepresentedCountry;
use Geo::Location::IP::Record::Traits;

field $continent :param :reader;
field $country :param :reader;
field $maxmind :param :reader;
field $registered_country :param :reader;
field $represented_country :param :reader;
field $traits :param :reader;

sub _from_hash ($class, $hash_ref, $ip_address, $locales) {
    my $continent = Geo::Location::IP::Record::Continent->_from_hash(
        $hash_ref->{continent} // {}, $locales);

    my $country
        = Geo::Location::IP::Record::Country->_from_hash($hash_ref->{country}
            // {}, $locales);

    my $maxmind
        = Geo::Location::IP::Record::MaxMind->_from_hash($hash_ref->{maxmind}
            // {});

    my $registered_country = Geo::Location::IP::Record::Country->_from_hash(
        $hash_ref->{registered_country} // {}, $locales);

    my $represented_country
        = Geo::Location::IP::Record::RepresentedCountry->_from_hash(
        $hash_ref->{represented_country} // {}, $locales);

    my $traits
        = Geo::Location::IP::Record::Traits->_from_hash($hash_ref->{traits}
            // {}, $ip_address);

    return $class->new(
        continent           => $continent,
        country             => $country,
        maxmind             => $maxmind,
        registered_country  => $registered_country,
        represented_country => $represented_country,
        traits              => $traits,
    );
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::Country - Records associated with a country

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file    => '/path/to/Country.mmdb',
    locales => ['de', 'en'],
  );
  eval {
    my $country_model = $reader->country(ip => '1.2.3.4');
    my $country       = $country_model->country;
    my $continent     = $country_model->continent;
    printf "%s in %s\n", $country->name, $continent->name;
  };

=head1 DESCRIPTION

This class contains records from a country database.

=head1 SUBROUTINES/METHODS

=head2 new

  my $country_model = Geo::Location::IP::Model::Country->new(
    continent           => $continent,
    country             => $country,
    maxmind             => $maxmind,
    registered_country  => $registered_country,
    represented_country => $represented_country,
    traits              => $traits,
  );

Creates a new object with records from an IP address query in a country
database.

All records may contain undefined values.

=head2 continent

  my $continent = $country_model->continent;

Returns a L<Geo::Location::IP::Record::Continent> object.

=head2 country

  my $country = $country_model->country;

Returns a L<Geo::Location::IP::Record::Country> object.

=head2 maxmind

  my $maxmind = $country_model->maxmind;

Returns a L<Geo::Location::IP::Record::MaxMind> object.

=head2 registered_country

  my $country = $country_model->registered_country;

Returns a L<Geo::Location::IP::Record::Country> object for the country where
the ISP registered the network.

=head2 represented_country

  my $country = $country_model->represented_country;

Returns a L<Geo::Location::IP::Record::RepresentedCountry> for the country
represented by the users of the IP address.  For example, the country
represented by an overseas military base.

=head2 traits

  my $traits = $country_model->traits;

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

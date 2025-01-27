package Geo::Location::IP::Record::Subdivision;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::Subdivision;

our $VERSION = 0.002;

apply Geo::Location::IP::Role::Record::HasConfidence;
apply Geo::Location::IP::Role::Record::HasGeoNameId;
apply Geo::Location::IP::Role::Record::HasNames;

field $iso_code :param :reader = undef;

sub _from_hash ($class, $hash_ref, $locales) {
    return $class->new(
        names      => $hash_ref->{names}      // {},
        confidence => $hash_ref->{confidence} // undef,
        geoname_id => $hash_ref->{geoname_id} // undef,
        iso_code   => $hash_ref->{iso_code}   // undef,
        locales    => $locales,
    );
}

use overload
    q{""} => \&stringify;

sub stringify {
    my $self = shift;

    return $self->name;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Record::Subdivision - Subdivision details

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/City.mmdb',
  );
  eval {
    my $city_model   = $reader->city(ip => '1.2.3.4');
    my @subdivisions = $city_model->subdivisions;
  };

=head1 DESCRIPTION

This class contains details about a subdivision associated with an IP address.

All fields may be undefined.

An IP address may be associated with multiple subdivisions such as federal
states, counties and provinces.

=head1 SUBROUTINES/METHODS

=head2 new

  my $subdivision = Geo::Location::IP::Record::Subdivision->new(
    names => {
      en => 'Westminster',
    },
    geoname_id => 3333218,
    iso_code   => 'WSM',
    locales    => ['en'],
  );

Creates a new subdivision record.

=head2 confidence

  my $confidence = $subdivision->confidence;

Returns a value in the range from 0 to 100 that indicates the confidence that
the subdivision is correct.

=head2 geoname_id

  my $geoname_id = $subdivision->geoname_id;

Returns the subdivision's GeoNames identifier as a number.

=head2 iso_code

  my $iso_code = $subdivision->iso_code;

Returns the region part of the subdivision's ISO 3166-2 code.

=head2 name

  my $name = $subdivision->name;

Returns the subdivision's name in the chosen language.

=head2 names

  my %names = %{$subdivision->names};

Returns a hash reference that maps locale codes to localized names.

=for Pod::Coverage DOES META stringify

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

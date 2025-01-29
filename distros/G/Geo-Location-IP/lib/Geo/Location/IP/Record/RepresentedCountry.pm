package Geo::Location::IP::Record::RepresentedCountry;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::RepresentedCountry
    :isa(Geo::Location::IP::Record::Country);

our $VERSION = 0.003;

field $type :param :reader = undef;

sub _from_hash ($class, $hash_ref, $locales) {
    return $class->new(
        names                => $hash_ref->{names}                // {},
        confidence           => $hash_ref->{confidence}           // undef,
        geoname_id           => $hash_ref->{geoname_id}           // undef,
        is_in_european_union => $hash_ref->{is_in_european_union} // 0,
        iso_code             => $hash_ref->{iso_code}             // undef,
        type                 => $hash_ref->{type}                 // undef,
        locales              => $locales,
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

Geo::Location::IP::Record::RepresentedCountry - Country details with a "type" field

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/City.mmdb',
  );
  eval {
    my $city_model = $reader->city(ip => '1.2.3.4');
    my $country    = $city_model->represented_country;
  };

=head1 DESCRIPTION

A L<Geo::Location::IP::Record::Country> subclass that adds a C<type> field.

This class contains details about the country represented by the users of an
IP address.  For example, the country represented by an overseas military
base.

All fields may be undefined.

=head1 SUBROUTINES/METHODS

=head2 new

  my $country = Geo::Location::IP::Record::RepresentedCountry->new(
    names => {
      de => 'USA',
      en => 'United States',
    },
    confidence           => 0,
    geoname_id           => 6252001,
    is_in_european_union => 0,
    iso_code             => 'US',
    type                 => 'military',
    locales              => ['de', 'en'],
  );

Creates a new country record with a C<type> field.

=head2 type

  my $type = $country->type;

Returns a type such as "military".

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

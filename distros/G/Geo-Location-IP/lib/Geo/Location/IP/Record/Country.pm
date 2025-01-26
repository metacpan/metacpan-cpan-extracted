package Geo::Location::IP::Record::Country;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::Country;

our $VERSION = 0.001;

apply Geo::Location::IP::Role::Record::HasConfidence;
apply Geo::Location::IP::Role::Record::HasGeoNameId;
apply Geo::Location::IP::Role::Record::HasNames;

field $is_in_european_union :param :reader = 0;
field $iso_code :param :reader             = undef;

sub _from_hash ($class, $hash_ref, $locales) {
    return $class->new(
        names                => $hash_ref->{names}                // {},
        confidence           => $hash_ref->{confidence}           // undef,
        geoname_id           => $hash_ref->{geoname_id}           // undef,
        is_in_european_union => $hash_ref->{is_in_european_union} // 0,
        iso_code             => $hash_ref->{iso_code}             // undef,
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

Geo::Location::IP::Record::Country - Country details

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/Country.mmdb',
  );
  eval {
    my $country_model = $reader->country(ip => '1.2.3.4');
    my $country       = $country_model->country;
  };

=head1 DESCRIPTION

This class contains details about the country associated with an IP address.

All fields may be undefined.

=head1 SUBROUTINES/METHODS

=head2 new

  my $country = Geo::Location::IP::Record::Country->new(
    names => {
      de => 'Deutschland',
      en => 'Germany',
      fr => 'Allemagne',
    },
    confidence           => 100,
    geoname_id           => 2921044,
    is_in_european_union => 1,
    iso_code             => 'DE',
    locales              => ['fr', 'en'],
  );

Creates a new country record.

=head2 confidence

  my $confidence = $country->confidence;

Returns a value in the range from 0 to 100 that indicates the confidence that
the country is correct.

=head2 geoname_id

  my $geoname_id = $country->geoname_id;

Returns the country's GeoNames identifier as a number.

=head2 is_in_european_union

  if ($country->is_in_european_union) {
    say 'Yippee!';
  }

Returns true if the country is in the European Union.

=head2 iso_code

  my $iso_code = $country->iso_code;

Returns a two-letter ISO 3166-1 country code.

=head2 name

  my $name = $country->name;

Returns the country's name in the chosen language.

=head2 names

  my %names = %{$country->names};

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

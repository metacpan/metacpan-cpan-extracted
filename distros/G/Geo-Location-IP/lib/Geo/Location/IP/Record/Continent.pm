package Geo::Location::IP::Record::Continent;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::Continent;

our $VERSION = 0.001;

apply Geo::Location::IP::Role::Record::HasGeoNameId;
apply Geo::Location::IP::Role::Record::HasNames;

field $code :param :reader = undef;

sub _from_hash ($class, $hash_ref, $locales) {
    return $class->new(
        names      => $hash_ref->{names}      // {},
        geoname_id => $hash_ref->{geoname_id} // undef,
        code       => $hash_ref->{code}       // undef,
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

Geo::Location::IP::Record::Continent - Continent details

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/City.mmdb',
  );
  eval {
    my $city_model = $reader->city(ip => '1.2.3.4');
    my $continent  = $city_model->continent;
  };

=head1 DESCRIPTION

This class contains details about the continent associated with an IP address.

All fields may be undefined.

=head1 SUBROUTINES/METHODS

=head2 new

  my $continent = Geo::Location::IP::Record::Continent->new(
    names => {
      de      => 'Europa',
      en      => 'Europe',
      'zh-CN' => '欧洲',
    },
    geoname_id => 6255148,
    code       => 'EU',
    locales    => ['zh-CN', 'en'],
  );

Creates a new continent record.

=head2 geoname_id

  my $geoname_id = $continent->geoname_id;

Returns the continent's GeoNames identifier as a number.

=head2 code

  my $code = $continent->code;

Returns a two-letter continent code.

Valid continent codes are:

=over

=item *

AF - Africa

=item *

AN - Antarctica

=item *

AS - Asia

=item *

EU - Europe

=item *

NA - North America

=item *

OC - Oceania

=item *

SA - South America

=back

=head2 name

  my $name = $continent->name;

Returns the continent's name in the chosen language.

=head2 names

  my %names = %{$continent->names};

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

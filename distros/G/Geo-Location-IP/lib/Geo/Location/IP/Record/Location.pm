package Geo::Location::IP::Record::Location;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::Location;

our $VERSION = 0.001;

field $accuracy_radius :param :reader    = undef;
field $average_income :param :reader     = undef;
field $latitude :param :reader           = undef;
field $longitude :param :reader          = undef;
field $metro_code :param :reader         = undef;
field $population_density :param :reader = undef;
field $time_zone :param :reader          = undef;

sub _from_hash ($class, $hash_ref) {
    return $class->new(
        accuracy_radius    => $hash_ref->{accuracy_radius}    // undef,
        average_income     => $hash_ref->{average_income}     // undef,
        latitude           => $hash_ref->{latitude}           // undef,
        longitude          => $hash_ref->{longitude}          // undef,
        metro_code         => $hash_ref->{metro_code}         // undef,
        population_density => $hash_ref->{population_density} // undef,
        time_zone          => $hash_ref->{time_zone}          // undef,
    );
}

use overload
    q{""} => \&stringify;

sub stringify {
    my $self = shift;

    if (defined $self->latitude && defined $self->longitude) {
        return sprintf "%g, %g", $self->latitude, $self->longitude;
    }
    return;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Record::Location - Location details

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/City.mmdb',
  );
  eval {
    my $city_model = $reader->city(ip => '1.2.3.4');
    my $location   = $city_model->location;
  };

=head1 DESCRIPTION

This class contains details about the location associated with an IP address.

All fields may be undefined.

=head1 SUBROUTINES/METHODS

=head2 new

  my $location = Geo::Location::IP::Record::Location->new(
    accuracy_radius    => 5,
    average_income     => 23_952,
    latitude           => 52.52,
    longitude          => 13.41,
    metro_code         => undef,
    population_density => 4100,
    time_zone          => 'Europe/Berlin',
  );

Creates a new location record.

=head2 accuracy_radius

  my $accuracy_radius = $location->accuracy_radius;

Returns the accuracy radius in kilometers.

The radius indicates the area around the geographical position where the IP
address is likely located.

=head2 average_income

  my $average_income = $location->average_income;

Returns the average income per year in US dollars in the area.

=head2 latitude

  my $latitude = $location->latitude;

Returns the area's latitude.

=head2 longitude

  my $longitude = $location->longitude;

Returns the area's longitude.

=head2 metro_code

  my $metro_code = $location->metro_code;

Returns a code for targeted advertising.  The metro code is deprecated.

=head2 population_density

  my $population_density = $location->population_density;

Returns the population per square kilometer.

=head2 time_zone

  my $time_zone = $location->time_zone;

Returns a name from the IANA time zone database such as "Europe/Berlin".

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

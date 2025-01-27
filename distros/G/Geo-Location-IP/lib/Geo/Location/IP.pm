package Geo::Location::IP;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

our $VERSION = 0.002;

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP - Map IP addresses to location information

=head1 VERSION

version 0.002

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

The modules in this distribution map IP addresses to location information such
as country and city names.

The distribution provides object-oriented wrapper classes for
L<IP::Geolocation::MMDB>.  The classes are similar to classes from the
deprecated GeoIP2 distribution.

=head1 SUBROUTINES/METHODS

See L<Geo::Location::IP::Database::Reader>.

=head1 DIAGNOSTICS

See L<Geo::Location::IP::Database::Reader>.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires Perl 5.026 and the modules L<IP::Geolocation::MMDB> and
L<Object::Pad>.

Requires databases in the MaxMind DB file format from
L<MaxMind|https://www.maxmind.com/> or L<DP-IP.com|https://db-ip.com/>.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

The distribution uses L<Object::Pad> but will use L<Feature::Compat::Class> as
soon as Perl supports roles, C<apply> statements and C<ADJUST :params>.

The differences to GeoIP2 are:

=over

=item *

You can only query database files.  A web service client is not included.

=item *

The provided classes aren't Moo classes.

=item *

Undocumented methods such as C<raw> are not available.

=item *

When catching exceptions, you need to keep in mind that the error classes are
L<Geo::Location::IP::Error::Generic> and
L<Geo::Location::IP::Error::AddressNotFound>.

=item *

IP addresses are returned as L<Geo::Location::IP::Address> objects.  The
objects stringify to the address.

=back

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

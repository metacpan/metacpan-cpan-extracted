package Geo::Location::IP::Error::AddressNotFound;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Error::AddressNotFound
    :isa(Geo::Location::IP::Error::Generic);

our $VERSION = 0.003;

field $ip_address :param :reader;

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Error::AddressNotFound - Error class for IP addresses

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use 5.036;
  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/Country.mmdb'
  );
  local $@;
  eval {
    my $country_model = $reader->country(ip => '192.0.2.1');
  };
  if (my $e = $@) {
    if ($e isa 'Geo::Location::IP::Error::AddressNotFound') {
      warn $e->ip_address, ' not found';
    }
  }

=head1 DESCRIPTION

A L<Geo::Location::IP::Error::Generic> subclass that signals a non-existing IP
address in a geolocation database.

=head1 SUBROUTINES/METHODS

=head2 throw

  Geo::Location::IP::Error::AddressNotFound->throw(
    message    => "No record found for IP address $ip_address",
    ip_address => $ip_address,
  );

Raises an exception with the specified message and a
L<Geo::Location::IP::Address> object.

=head2 message

  my $message = $e->message;

Returns the message.

=head2 ip_address

  my $ip_address = $e->ip_address;

Returns the IP address as a L<Geo::Location::IP::Address> object.

=for Pod::Coverage DOES META new

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

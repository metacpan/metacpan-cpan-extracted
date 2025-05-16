package Geo::Location::IP::Network;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Network;

our $VERSION = 0.005;

use Scalar::Util qw();
use Socket       qw();

field $network_address :reader;
field $prefixlen :param :reader;
field $version :reader;

method with_prefixlen () {
    if (defined $network_address) {
        return $network_address . '/' . $prefixlen;
    }
    return;
}

#<<<
ADJUST :params (:$address) {
    if (defined $address && defined $prefixlen && $prefixlen >= 0) {
        if ($prefixlen <= 32 && index($address, '.') >= 0) {
            my $family         = Socket::AF_INET;
            my $packed_address = Socket::inet_pton($family, $address);
            if (defined $packed_address) {
                my $packed_mask = ~pack 'N', (1 << (32 - $prefixlen)) - 1;
                $network_address = Socket::inet_ntop($family,
                    $packed_address & $packed_mask);
                $version = 4;
            }
        }
        elsif ($prefixlen <= 128 && index($address, ':') >= 0) {
            my $family         = Socket::AF_INET6;
            my $packed_address = Socket::inet_pton($family, $address);
            if (defined $packed_address) {
                my $bits        = '1' x $prefixlen . '0' x (128 - $prefixlen);
                my $packed_mask = pack 'B128', $bits;
                $network_address = Socket::inet_ntop($family,
                    $packed_address & $packed_mask);
                $version = 6;
            }
        }
    }
}
#>>>

use overload
    q{eq} => \&eq,
    q{""} => \&stringify;

sub eq {
    my ($self, $other) = @_;

    if (Scalar::Util::blessed($other)) {
        if ($other->isa(__PACKAGE__)) {
            return $self->with_prefixlen eq $other->with_prefixlen;
        }
    }
    return $self->with_prefixlen eq $other;
}

sub stringify {
    my $self = shift;

    return $self->with_prefixlen;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Network - IP network details

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/ASN.mmdb',
  );
  eval {
    my $asn_model  = $reader->asn(ip => '1.2.3.4');
    my $ip_address = $asn_model->ip_address;
    my $network    = $ip_address->network;
  };

=head1 DESCRIPTION

This class contains details about an IP network in a geolocation database.

=head1 SUBROUTINES/METHODS

=head2 new

  my $network = Geo::Location::IP::Network->new(
    address   => '1.2.3.0',
    prefixlen => 24,
  );

Creates an IP network object.

=head2 network_address

  my $network_address = $network->network_address;

Returns the network address as a string.

=head2 prefixlen

  my $prefixlen = $network->prefixlen;

Returns the network's prefix length as a number.

=head2 version

  my $version = $network->version;

Returns 4 or 6.

=head2 with_prefixlen

  my $address = $network->with_prefixlen;

Returns the network and prefix in CIDR notation.

Objects also stringify to their CIDR notation.

=for Pod::Coverage DOES META eq stringify

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires the L<Socket> module.

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

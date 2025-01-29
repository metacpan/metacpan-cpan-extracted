package Geo::Location::IP::Address;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Address;

our $VERSION = 0.003;

use Geo::Location::IP::Network;
use Scalar::Util qw();

field $address :param :reader;
field $network :param :reader;
field $version :reader;

ADJUST {
    if (defined $address) {
        if (defined $network && defined $network->version) {
            $version = $network->version;
        }
        else {
            if (index($address, '.') >= 0) {
                $version = 4;
                if (!defined $network) {
                    $network = Geo::Location::IP::Network->new(
                        address   => $address,
                        prefixlen => 32
                    );
                }
            }
            elsif (index($address, ':') >= 0) {
                $version = 6;
                if (!defined $network) {
                    $network = Geo::Location::IP::Network->new(
                        address   => $address,
                        prefixlen => 128
                    );
                }
            }
        }
    }
}

sub _from_hash ($class, $hash_ref, $ip_address) {
    # If a web service accepts "me" as an IP address, the returned IP address
    # may differ from the local host's IP address if the host is behind a NAT
    # gateway.
    if (exists $hash_ref->{ip_address}) {
        my $ip = $hash_ref->{ip_address};
        if (!defined $ip_address || $ip_address->address ne $ip) {
            $ip_address = $class->new(address => $ip, network => undef);
        }
    }
    return $ip_address;
}

use overload
    q{eq} => \&eq,
    q{""} => \&stringify;

sub eq {
    my ($self, $other) = @_;

    if (Scalar::Util::blessed($other)) {
        if ($other->isa(__PACKAGE__)) {
            return $self->address eq $other->address;
        }
    }
    return $self->address eq $other;
}

sub stringify {
    my $self = shift;

    return $self->address;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Address - IP address details

=head1 VERSION

version 0.003

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

This class contains details about an IP address in a geolocation database.

=head1 SUBROUTINES/METHODS

=head2 new

  my $ip_address = Geo::Location::IP::Address->new(
    address => '1.2.3.4',
    network => $network,
  );

Creates an IP address object.

=head2 address

  my $address = $ip_address->address;

Returns the address as a string.

Objects also stringify to their address.

=head2 network

  my $network = $ip_address->network;

Returns the network of the IP address as a L<Geo::Location::IP::Network>
object.

=head2 version

  my $version = $ip_address->version;

Returns 4 or 6.

=for Pod::Coverage DOES META eq stringify

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

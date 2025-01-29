package Geo::Location::IP::Model::ASN;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::ASN;

our $VERSION = 0.003;

apply Geo::Location::IP::Role::HasIPAddress;

field $autonomous_system_number :param :reader;
field $autonomous_system_organization :param :reader;

sub _from_hash ($class, $hash_ref, $ip_address) {
    my $autonomous_system_number = $hash_ref->{autonomous_system_number}
        // undef;

    my $autonomous_system_organization
        = $hash_ref->{autonomous_system_organization} // undef;

    return $class->new(
        autonomous_system_number       => $autonomous_system_number,
        autonomous_system_organization => $autonomous_system_organization,
        ip_address                     => $ip_address,
    );
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::ASN - Autonomous System details

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/ASN.mmdb',
  );
  eval {
    my $asn_model = $reader->asn(ip => '1.2.3.4');
    my $as_number = $asn_model->autonomous_system_number;
    printf "%d\n", $as_number;
  };

=head1 DESCRIPTION

This class contains details about an Autonomous System.

An Autonomous System is a connected group of one or more IP prefixes run by
one or more network operators.

=head1 SUBROUTINES/METHODS

=head2 new

  my $asn_model = Geo::Location::IP::Model::ASN->new(
    autonomous_system_number       => 12345,
    autonomous_system_organization => 'Acme Corporation',
    ip_address                     => $ip_address,
  );

Creates a new object with data from an IP address query in an ASN database.

All fields may contain undefined values.

=head2 autonomous_system_number

  my $as_number = $asn_model->autonomous_system_number;

Returns the Autonomous System number associated with the IP address the data
is for.

=head2 autonomous_system_organization

  my $as_organization = $asn_model->autonomous_system_organization;

Returns the name of the organization associated with the Autonomous System
number.

=head2 ip_address

  my $ip_address = $asn_model->ip_address;

Returns the IP address the data is for as a L<Geo::Location::IP::Address>
object.

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

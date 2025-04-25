package Geo::Location::IP::Model::ISP;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::ISP;

our $VERSION = 0.004;

apply Geo::Location::IP::Role::HasIPAddress;

field $autonomous_system_number :param :reader;
field $autonomous_system_organization :param :reader;
field $isp :param :reader;
field $organization :param :reader;

sub _from_hash ($class, $hash_ref, $ip_address) {
    my $autonomous_system_number = $hash_ref->{autonomous_system_number}
        // undef;

    my $autonomous_system_organization
        = $hash_ref->{autonomous_system_organization} // undef;

    my $isp = $hash_ref->{isp} // undef;

    my $organization = $hash_ref->{organization} // undef;

    return $class->new(
        autonomous_system_number       => $autonomous_system_number,
        autonomous_system_organization => $autonomous_system_organization,
        ip_address                     => $ip_address,
        isp                            => $isp,
        organization                   => $organization,
    );
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::ISP - ISP details

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/ISP.mmdb',
  );
  eval {
    my $isp_model = $reader->isp(ip => '1.2.3.4');
    my $isp       = $isp_model->isp;
    printf "%s\n", $isp;
  };

=head1 DESCRIPTION

This class contains details about an Internet Service Provider.

=head1 SUBROUTINES/METHODS

=head2 new

  my $isp_model = Geo::Location::IP::Model::ISP->new(
    autonomous_system_number       => 12345,
    autonomous_system_organization => 'Acme Corporation',
    ip_address                     => $ip_address,
    isp                            => 'Acme Telecom',
    organization                   => 'Acme Mobile',
  );

Creates a new object with data from an IP address query in an ISP database.

All fields may contain undefined values.

=head2 autonomous_system_number

  my $as_number = $isp_model->autonomous_system_number;

Returns the Autonomous System number associated with the IP address the data
is for.

=head2 autonomous_system_organization

  my $as_organization = $isp_model->autonomous_system_organization;

Returns the name of the organization associated with the Autonomous System
number.

=head2 ip_address

  my $ip_address = $isp_model->ip_address;

Returns the IP address the data is for as a L<Geo::Location::IP::Address>
object.

=head2 isp

  my $isp = $isp_model->isp;

Returns the name of the ISP associated with the IP address.

=head2 organization

  my $organization = $isp_model->organization;

Returns the name of the organization associated with the IP address.

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

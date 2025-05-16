package Geo::Location::IP::Model::Domain;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::Domain;

our $VERSION = 0.005;

apply Geo::Location::IP::Role::HasIPAddress;

field $domain :param :reader;

sub _from_hash ($class, $hash_ref, $ip_address) {
    my $domain = $hash_ref->{domain} // undef;

    return $class->new(
        domain     => $domain,
        ip_address => $ip_address,
    );
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::Domain - DNS domain details

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/Domain.mmdb',
  );
  eval {
    my $domain_model = $reader->domain(ip => '1.2.3.4');
    my $domain       = $domain_model->domain;
    printf "domain is %s\n", $domain;
  };

=head1 DESCRIPTION

This class contains details about a DNS domain.

=head1 SUBROUTINES/METHODS

=head2 new

  my $domain_model = Geo::Location::IP::Model::Domain->new(
    domain     => 'example.com'.
    ip_address => $ip_address,
  );

Creates a new object with data from an IP address query in a Domain database.

All fields may contain undefined values.

=head2 domain

  my $domain = $domain_model->domain;

Returns the domain name as a string.

=head2 ip_address

  my $ip_address = $domain_model->ip_address;

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

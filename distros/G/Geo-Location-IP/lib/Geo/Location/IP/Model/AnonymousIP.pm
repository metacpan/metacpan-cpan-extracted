package Geo::Location::IP::Model::AnonymousIP;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::AnonymousIP;

our $VERSION = 0.003;

apply Geo::Location::IP::Role::HasIPAddress;

field $is_anonymous :param :reader         = 0;
field $is_anonymous_vpn :param :reader     = 0;
field $is_hosting_provider :param :reader  = 0;
field $is_public_proxy :param :reader      = 0;
field $is_residential_proxy :param :reader = 0;
field $is_tor_exit_node :param :reader     = 0;

sub _from_hash ($class, $hash_ref, $ip_address) {
    return $class->new(
        ip_address           => $ip_address,
        is_anonymous         => $hash_ref->{is_anonymous}         // 0,
        is_anonymous_vpn     => $hash_ref->{is_anonymous_vpn}     // 0,
        is_hosting_provider  => $hash_ref->{is_hosting_provider}  // 0,
        is_public_proxy      => $hash_ref->{is_public_proxy}      // 0,
        is_residential_proxy => $hash_ref->{is_residential_proxy} // 0,
        is_tor_exit_node     => $hash_ref->{is_tor_exit_node}     // 0,
    );
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::AnonymousIP - Anonymity details

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/Anonymous-IP.mmdb',
  );
  eval {
    my $anon_ip_model = $reader->anonymous_ip(ip => '1.2.3.4');
    if ($anon_ip_model->is_anonymous) {
      printf "%s is anonymous\n", $anon_ip_model->ip_address;
    }
  };

=head1 DESCRIPTION

This class contains details about the anonymity of an IP address.

=head1 SUBROUTINES/METHODS

=head2 new

  my $anon_ip_model = Geo::Location::IP::Model::AnonymousIP->new(
    ip_address           => $ip_address,
    is_anonymous         => 0,
    is_anonymous_vpn     => 0,
    is_hosting_provider  => 0,
    is_public_proxy      => 0,
    is_residential_proxy => 0,
    is_tor_exit_node     => 0,
  );

Creates a new object with data from an IP address query in an Anonymous-IP
database.

=head2 ip_address

  my $ip_address = $anon_ip_model->ip_address;

Returns the IP address the data is for as a L<Geo::Location::IP::Address>
object.

=head2 is_anonymous

  my $is_anonymous = $anon_ip_model->is_anonymous;

Returns true if the C<ip_address> belongs to any sort of anonymous network.

=head2 is_anonymous_vpn

  my $is_anonymous_vpn = $anon_ip_model->is_anonymous_vpn;

Returns true if the C<ip_address> is known to belong to an anonymous VPN
provider.

=head2 is_hosting_provider

  my $is_hosting_provider = $anon_ip_model->is_hosting_provider;

Returns true if the C<ip_address> belongs to a hosting provider.

=head2 is_public_proxy

  my $is_public_proxy = $anon_ip_model->is_public_proxy;

Returns true if the C<ip_address> belongs to a public proxy.

=head2 is_residential_proxy

  my $is_residential_proxy = $anon_ip_model->is_residential_proxy;

Returns true if the C<ip_address> is on a suspected anonymizing network and
belongs to a residential ISP.

=head2 is_tor_exit_node

  my $is_tor_exit_node = $anon_ip_model->is_tor_exit_node;

Returns true if the C<ip_address> belongs to a Tor exit node.

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

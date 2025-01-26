package Geo::Location::IP::Record::Traits;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::Traits;

our $VERSION = 0.001;

use Geo::Location::IP::Address;

apply Geo::Location::IP::Role::HasIPAddress;

field $autonomous_system_number :param :reader       = undef;
field $autonomous_system_organization :param :reader = undef;
field $connection_type :param :reader                = undef;
field $domain :param :reader                         = undef;
field $is_anonymous :param :reader                   = 0;
field $is_anonymous_proxy :param :reader             = 0;
field $is_anonymous_vpn :param :reader               = 0;
field $is_anycast :param :reader                     = 0;
field $is_hosting_provider :param :reader            = 0;
field $is_legitimate_proxy :param :reader            = 0;
field $is_public_proxy :param :reader                = 0;
field $is_residential_proxy :param :reader           = 0;
field $is_satellite_provider :param :reader          = 0;
field $is_tor_exit_node :param :reader               = 0;
field $isp :param :reader                            = undef;
field $mobile_country_code :param :reader            = undef;
field $mobile_network_code :param :reader            = undef;
field $organization :param :reader                   = undef;
field $static_ip_score :param :reader                = undef;
field $user_count :param :reader                     = undef;
field $user_type :param :reader                      = undef;

sub _from_hash ($class, $hash_ref, $ip_address) {
    return $class->new(
        autonomous_system_number => $hash_ref->{autonomous_system_number}
            // undef,
        autonomous_system_organization =>
            $hash_ref->{autonomous_system_organization} // undef,
        connection_type => $hash_ref->{connection_type} // undef,
        domain          => $hash_ref->{domain}          // undef,
        ip_address      =>
            Geo::Location::IP::Address->_from_hash($hash_ref, $ip_address),
        is_anonymous          => $hash_ref->{is_anonymous}          // 0,
        is_anonymous_proxy    => $hash_ref->{is_anonymous_proxy}    // 0,
        is_anonymous_vpn      => $hash_ref->{is_anonymous_vpn}      // 0,
        is_anycast            => $hash_ref->{is_anycast}            // 0,
        is_hosting_provider   => $hash_ref->{is_hosting_provider}   // 0,
        is_legitimate_proxy   => $hash_ref->{is_legitimate_proxy}   // 0,
        is_public_proxy       => $hash_ref->{is_public_proxy}       // 0,
        is_residential_proxy  => $hash_ref->{is_residential_proxy}  // 0,
        is_satellite_provider => $hash_ref->{is_satellite_provider} // 0,
        is_tor_exit_node      => $hash_ref->{is_tor_exit_node}      // 0,
        isp                   => $hash_ref->{isp}                   // undef,
        mobile_country_code   => $hash_ref->{mobile_country_code}   // undef,
        mobile_network_code   => $hash_ref->{mobile_network_code}   // undef,
        organization          => $hash_ref->{organization}          // undef,
        static_ip_score       => $hash_ref->{static_ip_score}       // undef,
        user_count            => $hash_ref->{user_count}            // undef,
        user_type             => $hash_ref->{user_type}             // undef,
    );
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Record::Traits - Various details about an IP address

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/City.mmdb',
  );
  eval {
    my $city_model = $reader->city(ip => '1.2.3.4');
    my $traits     = $city_model->traits;
  };

=head1 DESCRIPTION

This class contains various details about an IP address.

All fields may be undefined.

=head1 SUBROUTINES/METHODS

=head2 new

  my $traits = Geo::Location::IP::Record::Traits->new(
    autonomous_system_number       => 12345,
    autonomous_system_organization => 'Acme Corporation',
    connection_type                => 'Cellular',
    domain                         => 'example.com',
    ip_address                     => $ip_address,
    is_anonymous                   => 0,
    is_anonymous_proxy             => 0,
    is_anonymous_vpn               => 0,
    is_anycast                     => 0,
    is_hosting_provider            => 0,
    is_legitimate_proxy            => 0,
    is_public_proxy                => 0,
    is_residential_proxy           => 0,
    is_satellite_provider          => 0,
    is_tor_exit_node               => 0,
    isp                            => 'Acme Telecom',
    mobile_country_code            => '001',
    mobile_network_code            => '01',
    organization                   => 'Acme Mobile',
    static_ip_score                => 0.0,
    user_count                     => 123,
    user_type                      => 'cellular',
  );

Creates a new traits record.

=head2 autonomous_system_number

  my $as_number = $traits->autonomous_system_number;

Returns the Autonomous System number associated with the IP address the data
is for.

=head2 autonomous_system_organization

  my $as_organization = $traits->autonomous_system_organization;

Returns the name of the organization associated with the Autonomous System
number.

=head2 connection_type

  my $connection_type = $traits->connection_type;

Returns the connection type as a string.  Common types are:

=over

=item *

Dialup

=item *

Cable/DSL

=item *

Corporate

=item *

Cellular

=item *

Satellite

=back

=head2 domain

  my $domain = $traits->domain;

Returns the second-level domain associated with the IP address.

=head2 ip_address

  my $ip_address = $traits->ip_address;

Returns the IP address the data is for as a L<Geo::Location::IP::Address>
object.

=head2 is_anonymous

  my $is_anonymous = $traits->is_anonymous;

Returns true if the IP address belongs to any sort of anonymous network.

=head2 is_anonymous_proxy

  my $is_anonymous_proxy = $traits->is_anonymous_proxy;

Returns true if the IP address belongs to an anonymous proxy server.  This
field is deprecated.

=head2 is_anonymous_vpn

  my $is_anonymous_vpn = $traits->is_anonymous_vpn;

Returns true if the IP address is known to belong to an anonymous VPN
provider.

=head2 is_anycast

  my $is_anycast = $traits->is_anycast;

Returns true if the IP address belongs to an anycast network.

=head2 is_hosting_provider

  my $is_hosting_provider = $traits->is_hosting_provider;

Returns true if the IP address belongs to a hosting provider.

=head2 is_legitimate_proxy

  my $is_legitimate_proxy = $traits->is_legitimate_proxy;

Returns true if the IP address is believed to be a legitimate proxy, such as
an internal VPN used by a corporation.

=head2 is_public_proxy

  my $is_public_proxy = $traits->is_public_proxy;

Returns true if the IP address belongs to a public proxy.

=head2 is_residential_proxy

  my $is_residential_proxy = $traits->is_residential_proxy;

Returns true if the IP address is on a suspected anonymizing network and
belongs to a residential ISP.

=head2 is_satellite_provider

  my $is_satellite_provider = $traits->is_satellite_provider;

Returns true if the IP address is from a satellite provider that provides
service to multiple countries.  This field is deprecated.

=head2 is_tor_exit_node

  my $is_tor_exit_node = $traits->is_tor_exit_node;

Returns true if the IP address is a Tor exit node.

=head2 isp

  my $isp = $traits->isp;

Returns the name of the Internet Service Provider associated with the IP
address.

=head2 mobile_country_code

  my $mcc = $traits->mobile_country_code;

Returns the mobile country code as a string.

=head2 mobile_network_code

  my $mnc = $traits->mobile_network_code;

Returns the mobile network code as a string.

=head2 organization

  my $organization = $traits->organization;

Returns the name of the organization associated with the IP address.

=head2 static_ip_score

  my $static_ip_score = $traits->static_ip_score;

Indicates how static or dynamic an IP address is.  The value ranges from 0.0
to 99.99 with higher values meaning a greater static association.

=head2 user_count

  my $user_count = $traits->user_count;

Returns the estimated number of users sharing the IP/network during the past
24 hours.

=head2 user_type

  my $user_type = $traits->user_type;

Returns the user type associated with the IP address as a string.  Common values are:

=over

=item *

business

=item *

cafe

=item *

cellular

=item *

college

=item *

consumer_privacy_network

=item *

content_delivery_network

=item *

dialup

=item *

government

=item *

hosting

=item *

library

=item *

military

=item *

residential

=item *

router

=item *

school

=item *

search_engine_spider

=item *

traveler

=back

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

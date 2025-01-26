#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Address;
use Geo::Location::IP::Network;
use Geo::Location::IP::Record::Traits;

my $ip = '1.2.3.4';

my $network = Geo::Location::IP::Network->new(
    address   => $ip,
    prefixlen => 24,
);

my $ip_address = Geo::Location::IP::Address->new(
    address => $ip,
    network => $network,
);

my %fields = (
    autonomous_system_number       => 12345,
    autonomous_system_organization => 'Acme Corporation',
    connection_type                => 'Cellular',
    domain                         => 'example.com',
    ip_address                     => $ip_address,
    is_anonymous                   => 0,
    is_anonymous_vpn               => 0,
    is_anycast                     => 0,
    is_hosting_provider            => 0,
    is_legitimate_proxy            => 0,
    is_public_proxy                => 0,
    is_residential_proxy           => 0,
    is_tor_exit_node               => 0,
    isp                            => 'Acme Telecom',
    mobile_country_code            => '001',
    mobile_network_code            => '01',
    organization                   => 'Acme Mobile',
    static_ip_score                => 0.0,
    user_count                     => 123,
    user_type                      => 'cellular',
);

my $traits = new_ok 'Geo::Location::IP::Record::Traits' => [%fields];

can_ok $traits, keys %fields;

is $traits->ip_address, $ip, 'IP address matches';

cmp_ok $traits->autonomous_system_number, '==',
    $fields{autonomous_system_number}, 'AS number matches';

is $traits->autonomous_system_organization,
    $fields{autonomous_system_organization}, 'AS organization matches';

is $traits->connection_type, $fields{connection_type},
    'connection_type matches';

is $traits->domain, $fields{domain}, 'domain matches';

ok !$traits->is_anonymous, 'is not anonymous';

ok !$traits->is_anonymous_proxy, 'anonymous proxy defaults to false';

ok !$traits->is_anonymous_vpn, 'is no anonymous VPN';

ok !$traits->is_anycast, 'is no anycast network';

ok !$traits->is_hosting_provider, 'is no hosting provider';

ok !$traits->is_legitimate_proxy, 'is no legitimate proxy';

ok !$traits->is_public_proxy, 'is no public proxy';

ok !$traits->is_residential_proxy, 'is no residential proxy';

ok !$traits->is_satellite_provider, 'satellite provider defauls to false';

ok !$traits->is_tor_exit_node, 'is no Tor exit node';

is $traits->isp, $fields{isp}, 'ISP matches';

is $traits->organization, $fields{organization}, 'Organization matches';

is $traits->mobile_country_code, $fields{mobile_country_code}, 'MCC matches';

is $traits->mobile_network_code, $fields{mobile_network_code}, 'MNC matches';

cmp_ok $traits->static_ip_score, '==', $fields{static_ip_score},
    'static IP score matches';

cmp_ok $traits->user_count, '==', $fields{user_count}, 'user count matches';

is $traits->user_type, $fields{user_type}, 'user type matches';

done_testing;

#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Address;
use Geo::Location::IP::Network;
use Geo::Location::IP::Model::AnonymousIP;

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
    ip_address           => $ip_address,
    is_anonymous         => 1,
    is_anonymous_vpn     => 0,
    is_hosting_provider  => 0,
    is_public_proxy      => 0,
    is_residential_proxy => 0,
    is_tor_exit_node     => 1,
);

my $model = new_ok 'Geo::Location::IP::Model::AnonymousIP' => [%fields];

can_ok $model, keys %fields;

is $model->ip_address, $ip, 'IP address matches';

ok $model->is_anonymous, 'is anonymous';

ok !$model->is_anonymous_vpn, 'is no anonymous VPN';

ok !$model->is_hosting_provider, 'is no hosting provider';

ok !$model->is_public_proxy, 'is no public proxy';

ok !$model->is_residential_proxy, 'is no residential proxy';

ok $model->is_tor_exit_node, 'is Tor exit node';

done_testing;

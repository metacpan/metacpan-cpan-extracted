#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Address;
use Geo::Location::IP::Network;
use Geo::Location::IP::Model::ConnectionType;

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
    connection_type => 'Dialup',
    ip_address      => $ip_address,
);

my $model = new_ok 'Geo::Location::IP::Model::ConnectionType' => [%fields];

can_ok $model, keys %fields;

is $model->connection_type, 'Dialup', 'connection type is "Dialup"';

is $model->ip_address, $ip, 'IP address matches';

done_testing;

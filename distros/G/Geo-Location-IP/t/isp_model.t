#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Address;
use Geo::Location::IP::Model::ISP;
use Geo::Location::IP::Network;

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
    isp                            => 'Acme Telecom',
    organization                   => 'Acme Mobile',
);

my $model = new_ok 'Geo::Location::IP::Model::ISP' => [
    raw        => \%fields,
    ip_address => $ip_address,
];

can_ok $model, qw(ip_address), keys %fields;

cmp_ok $model->autonomous_system_number, '==',
    $fields{autonomous_system_number}, 'autonomous_system_number matches';

is $model->autonomous_system_organization,
    $fields{autonomous_system_organization},
    'autonomous_system_organization matches';

is $model->ip_address, $ip, 'ip_address matches';

is $model->isp, $fields{isp}, 'ISP matches';

is $model->organization, $fields{organization}, 'Organization matches';

done_testing;

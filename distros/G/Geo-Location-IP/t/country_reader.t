#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file    = catfile(qw(t data Test-Country.mmdb));
my $locales = ['de', 'en'];

my $reader = new_ok 'Geo::Location::IP::Database::Reader' =>
    [file => $file, locales => $locales];
can_ok $reader, qw(country file locales metadata);
is $reader->file, $file, 'file matches';
is_deeply $reader->locales, $locales, 'locales match';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{Country}, 'is a Country database';

my $ip = '176.9.54.163';

my $model = $reader->country(ip => $ip);

my $continent = $model->continent;
is $continent->name, 'Europa', 'continent name is "Europa"';
isa_ok $continent->names, 'HASH';
is $continent->code, 'EU', 'continent code is "EU"';
cmp_ok $continent->geoname_id, '==', 6255148,
    'continent geoname_id is 6255148';

my $country = $model->country;
is $country->name, 'Deutschland', 'country name is "Deutschland"';
isa_ok $country->names, 'HASH';
cmp_ok $country->confidence, '==', 100,     'country confidence is 100';
cmp_ok $country->geoname_id, '==', 2921044, 'country geoname_id is 2921044';
ok $country->is_in_european_union, 'country is in European union';
is $country->iso_code, 'DE', 'country code is "DE"';

my $registered_country = $model->registered_country;
is $registered_country->name, 'Deutschland',
    'registered country is "Deutschland"';

my $represented_country = $model->represented_country;
is $represented_country->name, 'USA', 'represented country is "USA"';
is $represented_country->type, 'military',
    'represented country type is "military"';

my $traits = $model->traits;
cmp_ok $traits->autonomous_system_number, '==', 24940, 'ASN is 24940';
is $traits->autonomous_system_organization, 'Hetzner Online GmbH',
    'organization is Hetzner';

my $ip_address = $traits->ip_address;
is $ip_address, $ip, 'IP address matches';

my $network = $ip_address->network;
is $network, '176.9.0.0/16', 'network is "176.9.0.0/16"';
cmp_ok $network->version, '==', 4, 'is IPv4 network';

done_testing;

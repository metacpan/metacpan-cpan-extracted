#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file = catfile(qw(t data Test-ASN.mmdb));

my $reader = new_ok 'Geo::Location::IP::Database::Reader' => [file => $file];
can_ok $reader, qw(asn file metadata);
is $reader->file, $file, 'file matches';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{ASN}, 'is an ASN database';

ok !eval { $reader->asn(ip => '192.0.2.1') },
    'no result for unknown IP address';

my $ip = '176.9.54.163';

my $model = $reader->asn(ip => $ip);

cmp_ok $model->autonomous_system_number, '==', 24940, 'ASN is 24940';

is $model->autonomous_system_organization, 'Hetzner Online GmbH',
    'AS organization is Hetzner';

my $ip_address = $model->ip_address;
is $ip_address, $ip, 'IP address matches';

done_testing;

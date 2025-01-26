#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file = catfile(qw(t data Test-ISP.mmdb));

my $reader = new_ok 'Geo::Location::IP::Database::Reader' => [file => $file];
can_ok $reader, qw(isp file metadata);
is $reader->file, $file, 'file matches';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{ISP}, 'is an ISP database';

ok !eval { $reader->isp(ip => '192.0.2.1') },
    'no result for unknown IP address';

my $ip = '176.9.54.163';

my $model = $reader->isp(ip => $ip);

cmp_ok $model->autonomous_system_number, '==', 24940, 'ASN is 24940';

is $model->autonomous_system_organization, 'Hetzner Online GmbH',
    'AS organization is Hetzner';

my $ip_address = $model->ip_address;
is $ip_address, $ip, 'IP address matches';

is $model->isp, 'Some ISP', 'ISP matches';

is $model->organization, 'Some Organization', 'Organization matches';

done_testing;

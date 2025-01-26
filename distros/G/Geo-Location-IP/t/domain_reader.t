#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file = catfile(qw(t data Test-Domain.mmdb));

my $reader = new_ok 'Geo::Location::IP::Database::Reader' => [file => $file];
can_ok $reader, qw(domain file metadata);
is $reader->file, $file, 'file matches';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{Domain}, 'is a Domain database';

ok !eval { $reader->domain(ip => '192.0.2.1') },
    'no result for unknown IP address';

my $ip = '176.9.54.163';

my $model = $reader->domain(ip => $ip);

is $model->domain, 'example.com', 'domain type is "example.com"';

my $ip_address = $model->ip_address;
is $ip_address, $ip, 'IP address matches';

done_testing;

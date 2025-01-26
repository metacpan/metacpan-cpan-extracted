#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file = catfile(qw(t data Test-Connection-Type.mmdb));

my $reader = new_ok 'Geo::Location::IP::Database::Reader' => [file => $file];
can_ok $reader, qw(connection_type file metadata);
is $reader->file, $file, 'file matches';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{Connection-Type},
    'is a Connection-Type database';

ok !eval { $reader->connection_type(ip => '192.0.2.1') },
    'no result for unknown IP address';

my $ip = '176.9.54.163';

my $model = $reader->connection_type(ip => $ip);

is $model->connection_type, 'Corporate', 'connection type is "Corporate"';

my $ip_address = $model->ip_address;
is $ip_address, $ip, 'IP address matches';

done_testing;

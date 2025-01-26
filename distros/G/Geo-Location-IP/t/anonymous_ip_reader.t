#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file = catfile(qw(t data Test-Anonymous-IP.mmdb));

my $reader = new_ok 'Geo::Location::IP::Database::Reader' => [file => $file];
can_ok $reader, qw(anonymous_ip file metadata);
is $reader->file, $file, 'file matches';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{Anonymous-IP},
    'is an Anonymous-IP database';

ok !eval { $reader->anonymous_ip(ip => '192.0.2.1') },
    'no result for unknown IP address';

my $ip = '176.9.54.163';

my $model = $reader->anonymous_ip(ip => $ip);

ok $model->is_anonymous,        'is anonymous';
ok !$model->is_anonymous_vpn,   'is no anonymous VPN';
ok $model->is_hosting_provider, 'is hosting provider';

my $ip_address = $model->ip_address;
is $ip_address, $ip, 'IP address matches';

done_testing;

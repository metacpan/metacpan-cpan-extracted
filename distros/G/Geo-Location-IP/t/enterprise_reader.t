#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file    = catfile(qw(t data Test-Enterprise.mmdb));
my $locales = ['de', 'en'];

my $reader = new_ok 'Geo::Location::IP::Database::Reader' =>
    [file => $file, locales => $locales];
can_ok $reader, qw(enterprise file locales metadata);
is $reader->file, $file, 'file matches';
is_deeply $reader->locales, $locales, 'locales match';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{Enterprise}, 'is an Enterprise database';

ok !eval { $reader->enterprise(ip => '192.0.2.1') },
    'no result for unknown IP address';

my $model = $reader->enterprise(ip => '176.9.54.163');

my $city = $model->city;
is $city->name, 'Falkenstein', 'city name is "Falkenstein"';

done_testing;

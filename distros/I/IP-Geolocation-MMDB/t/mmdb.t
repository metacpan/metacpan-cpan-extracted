#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Test::More tests => 11;

use File::Spec::Functions qw(catfile);
use IP::Geolocation::MMDB;

ok !eval { IP::Geolocation::MMDB->new },
  'constructor without "file" parameter dies';

ok !eval { IP::Geolocation::MMDB->new(file => 'nonexistent') },
  'constructor with non-existing file dies';

my $file = catfile(qw(t data Test-GeoLite2-Country.mmdb));

my $mmdb = new_ok 'IP::Geolocation::MMDB' => [file => $file];

can_ok $mmdb, qw(getcc record_for_address version);

isnt $mmdb->version, q{}, 'library version is not empty';

ok !eval { $mmdb->record_for_address('-1') },
  'invalid ip address throws exception';

ok !$mmdb->record_for_address('127.0.0.1'), 'no data for localhost';

isa_ok $mmdb->record_for_address('176.9.54.163'), 'HASH';
is $mmdb->getcc('176.9.54.163'), 'DE', 'IPv4 address is in Germany';

SKIP:
{
  skip 'IPv6 tests on Windows', 2 if $^O eq 'MSWin32';

  isa_ok $mmdb->record_for_address('2a01:4f8:150:74ab::2'), 'HASH';
  is $mmdb->getcc('2a01:4f8:150:74ab::2'), 'DE', 'IPv6 address is in Germany';
}

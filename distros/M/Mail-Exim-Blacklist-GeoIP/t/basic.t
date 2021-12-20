#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

BEGIN {
  use File::Spec::Functions qw(catfile);
  $ENV{GEOIP_COUNTRY} = catfile(qw(t test-data Test-GeoLite2-Country.mmdb));
  use_ok 'Mail::Exim::Blacklist::GeoIP', qw(geoip_country_code);
}

is geoip_country_code('176.9.54.163'), 'DE',
  'IPv4 address is mapped to country code';
is geoip_country_code('2a01:4f8:150:74ab::2'), 'DE',
  'IPv6 address is mapped to country code';

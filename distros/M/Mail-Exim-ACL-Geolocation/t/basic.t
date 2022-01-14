#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Test::More tests => 3;

BEGIN {
  use File::Spec::Functions qw(catfile);
  $ENV{IP_GEOLOCATION_MMDB} = catfile(qw(t data Test-City.mmdb));
  use_ok 'Mail::Exim::ACL::Geolocation', qw(country_code);
}

is country_code('176.9.54.163'), 'DE', 'IPv4 address is in Germany';

SKIP:
{
  skip 'IPv6 tests on Windows', 1 if $^O eq 'MSWin32';

  is country_code('2a01:4f8:150:74ab::2'), 'DE', 'IPv6 address is in Germany';
}

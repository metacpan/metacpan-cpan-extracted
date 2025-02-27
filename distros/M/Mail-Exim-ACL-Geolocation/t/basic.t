#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Test::More tests => 4;

BEGIN {
    use File::Spec::Functions qw(catfile);
    $ENV{COUNTRY_DB} = catfile(qw(t data Test-Country.mmdb));
    $ENV{ASN_DB}     = catfile(qw(t data Test-ASN.mmdb));
    use_ok 'Mail::Exim::ACL::Geolocation', qw(country_code asn_lookup);
}

is country_code('176.9.54.163'), 'DE', 'IPv4 address is in Germany';

like asn_lookup('176.9.54.163'), qr{^24940\b}, 'Autonomous System is 24940';

SKIP:
{
    skip 'IPv6 tests on Windows', 1 if $^O eq 'MSWin32';

    is country_code('2a01:4f8:150:74ab::2'), 'DE',
        'IPv6 address is in Germany';
}

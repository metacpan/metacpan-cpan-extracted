# -*- Mode: Perl; -*-

use strict;
use Test;

$^W = 1;

BEGIN { plan tests => 11 }

use Geo::IP;

my $gi = Geo::IP->new(GEOIP_MEMORY_CACHE);

while (<DATA>) {
    chomp;
    my ( $host, $exp_country ) = split("\t");
    my $country = $gi->country_code_by_name($host);
    ok( $country, $exp_country );
}

__DATA__
203.174.65.12	JP
212.208.74.140	FR
200.219.192.106	BR
134.102.101.18	DE
193.75.148.28	BE
134.102.101.18	DE
147.251.48.1	CZ
194.244.83.2	IT
203.15.106.23	AU
196.31.1.1	ZA
yahoo.com	US

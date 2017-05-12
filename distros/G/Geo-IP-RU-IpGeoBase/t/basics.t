#!/ust/bin/env perl

use strict;
use warnings;

use Test::More;

require Geo::IP::RU::IpGeoBase;

my ($dsn, $user, $pass) = @ENV{
    qw(IP_GEO_BASE_TEST IP_GEO_BASE_USER IP_GEO_BASE_PASS)
};

if ( $dsn ) {
    plan tests => 1;
}
else {
    plan skip_all => "No DSN for testing";
}

ok(1);

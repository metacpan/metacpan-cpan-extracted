use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Geo/IP.pm',
    'lib/Geo/IP/Record.pm',
    'lib/Geo/IP/Record.pod',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/city.t',
    't/country.t',
    't/country_v6.t',
    't/domain.t',
    't/netspeedcell.t',
    't/org.t',
    't/region.t'
);

notabs_ok($_) foreach @files;
done_testing;

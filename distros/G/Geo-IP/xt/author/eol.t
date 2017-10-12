use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

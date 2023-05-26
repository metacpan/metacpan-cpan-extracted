use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Exporter/Handy.pm',
    'lib/Exporter/Handy/Util.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-xtags.t',
    't/02-basic.t',
    't/02-export.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

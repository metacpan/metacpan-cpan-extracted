use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/ReportVersions/Tiny.pm',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/3part_prereq.t',
    't/exclude.t',
    't/include.t',
    't/lib/MockZilla.pm',
    't/version-compare-as-number.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

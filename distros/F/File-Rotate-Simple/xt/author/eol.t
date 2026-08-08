use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/Rotate/Simple.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001-_rotated_name.t',
    't/100-default.t',
    't/100-legacy.t',
    't/101-CVE-2026-17435.t',
    't/200-exports.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

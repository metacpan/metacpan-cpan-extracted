use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Memoize/HashKey/Ignore.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-ignore.t',
    't/02-ignore.t',
    't/boilerplate.t',
    't/manifest.t',
    't/pod-coverage.t',
    't/pod.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

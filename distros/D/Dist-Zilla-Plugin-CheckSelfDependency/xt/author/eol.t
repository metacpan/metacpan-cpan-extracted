use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/CheckSelfDependency.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-extra-modules.t',
    't/03-develop-phase.t',
    't/04-file-in-memory.t',
    't/05-encoding.t',
    't/06-test-module.t',
    't/zzz-check-breaks.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

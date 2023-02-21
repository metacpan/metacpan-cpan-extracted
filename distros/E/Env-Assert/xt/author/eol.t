use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Env/Assert.pm',
    'script/envassert',
    't/env-assert-private.t',
    't/env-assert-public-assert.t',
    't/env-assert-public-report_errors.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

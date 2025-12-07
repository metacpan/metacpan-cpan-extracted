use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/envassert',
    'lib/Env/Assert.pm',
    't/env-assert-private.t',
    't/env-assert-public-assert.t',
    't/env-assert-public-report_errors.t'
);

notabs_ok($_) foreach @files;
done_testing;

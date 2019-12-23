use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/is-sorted',
    'lib/App/File/IsSorted.pm',
    'lib/App/File/IsSorted/Command/check.pm',
    'lib/File/IsSorted.pm',
    'lib/Test/File/IsSorted.pm',
    't/00-compile.t',
    't/core-api.t',
    't/test-test-module.t'
);

notabs_ok($_) foreach @files;
done_testing;

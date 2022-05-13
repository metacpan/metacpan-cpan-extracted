use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/is-sorted',
    'lib/App/File/IsSorted.pm',
    'lib/App/File/IsSorted/Command/check.pm',
    'lib/File/IsSorted.pm',
    'lib/Test/File/IsSorted.pm',
    't/00-compile.t',
    't/core-api.t',
    't/test-test-module.t',
    't/test-test-module2.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

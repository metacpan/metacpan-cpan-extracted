use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Generic/Assertions.pm',
    't/00-compile/lib_Generic_Assertions_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/construction_basic.t',
    't/construction_handlers.t',
    't/construction_tests.t',
    't/core_handlers.t',
    't/core_handlers_methods.t',
    't/input_transformer.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

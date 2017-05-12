use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Linux/AtaSmart.pm',
    'lib/Linux/AtaSmart/Constants.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.t',
    't/01-main.t'
);

notabs_ok($_) foreach @files;
done_testing;

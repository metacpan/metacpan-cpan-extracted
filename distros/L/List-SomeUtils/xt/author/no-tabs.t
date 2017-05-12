use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/List/SomeUtils.pm',
    'lib/List/SomeUtils/PP.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Functions.t',
    't/Import.t',
    't/ab.t',
    't/lib/LSU/Test/Functions.pm',
    't/lib/LSU/Test/Import.pm',
    't/lib/LSU/Test/ab.pm',
    't/lib/Test/LSU.pm',
    't/pp-only.t'
);

notabs_ok($_) foreach @files;
done_testing;

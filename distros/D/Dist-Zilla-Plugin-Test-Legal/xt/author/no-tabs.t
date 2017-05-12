use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Test/Legal.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-compile/lib_Dist_Zilla_Plugin_Test_Legal_pm.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/000-report-versions.t'
);

notabs_ok($_) foreach @files;
done_testing;

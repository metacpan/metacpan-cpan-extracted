use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.07

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Role/ContributorSource.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/basic.t'
);

notabs_ok($_) foreach @files;
done_testing;

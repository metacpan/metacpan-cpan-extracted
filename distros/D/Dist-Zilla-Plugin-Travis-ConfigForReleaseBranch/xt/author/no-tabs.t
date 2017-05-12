use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Travis/ConfigForReleaseBranch.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t'
);

notabs_ok($_) foreach @files;
done_testing;

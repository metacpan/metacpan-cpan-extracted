use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/App/Command/chainsmoke.pm',
    'lib/Dist/Zilla/App/CommandHelper/ChainSmoking.pm',
    'lib/Dist/Zilla/Plugin/Travis/TestRelease.pm',
    'lib/Dist/Zilla/Plugin/TravisYML.pm',
    'lib/Dist/Zilla/Role/TravisYML.pm',
    'lib/Dist/Zilla/TravisCI.pod',
    'lib/Dist/Zilla/TravisCI/MVDT.pod',
    'lib/Dist/Zilla/Util/Git/Bundle.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t'
);

notabs_ok($_) foreach @files;
done_testing;

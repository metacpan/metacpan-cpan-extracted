use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/App/Command/weave.pm',
    'lib/Dist/Zilla/Plugin/Test/WeaveFile.pm',
    'lib/Dist/Zilla/Plugin/WeaveFile.pm',
    'lib/Dist/Zilla/Plugin/WeaveFile/Engine.pm',
    't/00-load.t',
    't/engine.t',
    't/integration.t'
);

notabs_ok($_) foreach @files;
done_testing;

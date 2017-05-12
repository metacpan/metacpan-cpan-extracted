use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/PluginBundle/AJGB.pm',
    'lib/Pod/Weaver/PluginBundle/AJGB.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;

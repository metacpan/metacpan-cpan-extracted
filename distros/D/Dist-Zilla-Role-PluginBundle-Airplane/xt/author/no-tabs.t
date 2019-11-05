use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Role/PluginBundle/Airplane.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/lib/Dist/Zilla/PluginBundle/TestAirplane.pm'
);

notabs_ok($_) foreach @files;
done_testing;

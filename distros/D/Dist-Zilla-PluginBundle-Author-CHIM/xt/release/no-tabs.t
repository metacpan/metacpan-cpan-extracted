use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/PluginBundle/Author/CHIM.pm',
    'lib/Pod/Weaver/PluginBundle/CHIM.pm',
    't/00-compile.t',
    't/01-basic.t'
);

notabs_ok($_) foreach @files;
done_testing;

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/MinimumPrereqs.pm',
    'lib/Dist/Zilla/Plugin/PrereqsClean.pm',
    'lib/Dist/Zilla/PluginBundle/Prereqs.pm'
);

notabs_ok($_) foreach @files;
done_testing;

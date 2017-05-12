use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Config/BundleInspector.pm',
    'lib/Dist/Zilla/Plugin/BundleInspector.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attr.t',
    't/data/recovering_the_satellites/lib/Dist/Zilla/PluginBundle/Catapult.pm',
    't/data/recovering_the_satellites/lib/Pod/Weaver/PluginBundle/ChildrenInBloom.pm',
    't/inspector.t',
    't/lib/TestBundleHelpers.pm',
    't/lib/TestBundles.pm',
    't/plugin.t'
);

notabs_ok($_) foreach @files;
done_testing;

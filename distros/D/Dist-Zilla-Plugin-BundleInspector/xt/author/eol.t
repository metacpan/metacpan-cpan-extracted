use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

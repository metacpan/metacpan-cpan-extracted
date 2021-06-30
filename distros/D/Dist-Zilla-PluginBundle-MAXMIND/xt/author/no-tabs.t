use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/MAXMIND/CheckChangesHasContent.pm',
    'lib/Dist/Zilla/Plugin/MAXMIND/Contributors.pm',
    'lib/Dist/Zilla/Plugin/MAXMIND/License.pm',
    'lib/Dist/Zilla/Plugin/MAXMIND/TidyAll.pm',
    'lib/Dist/Zilla/Plugin/MAXMIND/VersionProvider.pm',
    'lib/Dist/Zilla/Plugin/MAXMIND/WeaverConfig.pm',
    'lib/Dist/Zilla/PluginBundle/MAXMIND.pm',
    'lib/Pod/Weaver/PluginBundle/MAXMIND.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

notabs_ok($_) foreach @files;
done_testing;

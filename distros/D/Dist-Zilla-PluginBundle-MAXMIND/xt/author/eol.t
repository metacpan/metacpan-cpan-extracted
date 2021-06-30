use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

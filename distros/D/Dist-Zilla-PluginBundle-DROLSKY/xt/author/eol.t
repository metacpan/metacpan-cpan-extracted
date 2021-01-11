use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/DROLSKY/BundleAuthordep.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/Contributors.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/DevTools.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/Git/CheckFor/CorrectBranch.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/License.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/MakeMaker.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/PerlLinterConfigFiles.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/Precious.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/Role/CoreCounter.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/Role/MaybeFileWriter.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/RunExtraTests.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/Test/Precious.pm',
    'lib/Dist/Zilla/Plugin/DROLSKY/WeaverConfig.pm',
    'lib/Dist/Zilla/PluginBundle/DROLSKY.pm',
    'lib/Pod/Weaver/PluginBundle/DROLSKY.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

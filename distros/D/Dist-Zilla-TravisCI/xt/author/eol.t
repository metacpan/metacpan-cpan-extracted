use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/App/Command/chainsmoke.pm',
    'lib/Dist/Zilla/App/CommandHelper/ChainSmoking.pm',
    'lib/Dist/Zilla/Plugin/Travis/TestRelease.pm',
    'lib/Dist/Zilla/Plugin/TravisYML.pm',
    'lib/Dist/Zilla/Role/TravisYML.pm',
    'lib/Dist/Zilla/TravisCI.pod',
    'lib/Dist/Zilla/TravisCI/MVDT.pod',
    'lib/Dist/Zilla/Util/Git/Bundle.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;

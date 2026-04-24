use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/App/Command/weave.pm',
    'lib/Dist/Zilla/Plugin/Test/WeaveFile.pm',
    'lib/Dist/Zilla/Plugin/WeaveFile.pm',
    'lib/Dist/Zilla/Plugin/WeaveFile/Engine.pm',
    't/00-load.t',
    't/engine.t',
    't/integration.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/MintingProfile/MapMetro/Map.pm',
    'lib/Dist/Zilla/Plugin/MapMetro/MintMapFiles.pm',
    'lib/Dist/Zilla/Plugin/MapMetro/MintMetroFile.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

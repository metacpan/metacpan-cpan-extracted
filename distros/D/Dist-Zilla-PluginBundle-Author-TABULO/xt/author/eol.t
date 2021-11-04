use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/MintingProfile/Author/TABULO.pm',
    'lib/Dist/Zilla/PluginBundle/Author/TABULO.pm',
    'lib/Pod/Weaver/PluginBundle/Author/TABULO.pm',
    'lib/Pod/Wordlist/Author/TABULO.pm',
    'lib/Zest/Author/TABULO/MungersForHas.pm',
    'lib/Zest/Author/TABULO/Util.pm',
    'lib/Zest/Author/TABULO/Util/Dzil.pm',
    'lib/Zest/Author/TABULO/Util/List.pm',
    'lib/Zest/Author/TABULO/Util/Mayhap.pm',
    'lib/Zest/Author/TABULO/Util/ShareDir.pm',
    'lib/Zest/Author/TABULO/Util/Text.pm',
    't/.gitignore',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/build_basic.t',
    't/build_more.t',
    't/minter.t',
    't/minter/global/config.ini'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

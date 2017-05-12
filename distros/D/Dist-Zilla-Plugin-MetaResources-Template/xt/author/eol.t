use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'Changes',
    'GPLv3',
    'VERSION',
    'ex/Assa/dist.ini',
    'lib/Dist/Zilla/Plugin/MetaResources/Template.pm',
    'lib/Dist/Zilla/Plugin/MetaResources/Template/Manual.pod',
    't/metaresources-template.t',
    'xt/aspell-en.pws',
    'xt/example.t',
    'xt/perlcritic.ini'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

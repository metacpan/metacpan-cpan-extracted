use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'Changes',
    'GPLv3',
    'VERSION',
    'lib/Dist/Zilla/Plugin/Manifest/Read.pm',
    'lib/Dist/Zilla/Plugin/Manifest/Read/Manual.pod',
    't/manifest-read.t',
    'xt/aspell-en.pws',
    'xt/perlcritic.ini'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

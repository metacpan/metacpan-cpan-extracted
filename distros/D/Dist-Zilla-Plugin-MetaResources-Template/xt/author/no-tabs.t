use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;

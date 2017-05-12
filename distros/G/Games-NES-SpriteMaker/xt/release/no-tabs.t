use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/pnm2chr',
    'lib/Games/NES/SpriteMaker.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;

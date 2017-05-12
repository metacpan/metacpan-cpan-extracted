use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Inky.pm',
    't/00-compile.t',
    't/001-loads.t',
    't/002_basic.t'
);

notabs_ok($_) foreach @files;
done_testing;

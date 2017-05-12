use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Image/PNM.pm',
    't/00-compile.t',
    't/P1.t',
    't/P2.t',
    't/P3.t',
    't/P4.t',
    't/P5.t',
    't/P6.t',
    't/data/P1.pbm',
    't/data/P2.pgm',
    't/data/P3.ppm',
    't/data/P4.pbm',
    't/data/P5.pgm',
    't/data/P6.ppm',
    't/write.t'
);

notabs_ok($_) foreach @files;
done_testing;

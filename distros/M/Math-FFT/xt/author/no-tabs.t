use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Math/FFT.pm',
    't/00-compile.t',
    't/apps.t',
    't/fft.t',
    't/lib/MathFftResults.pm',
    't/spctrl.dat',
    't/stats.t'
);

notabs_ok($_) foreach @files;
done_testing;

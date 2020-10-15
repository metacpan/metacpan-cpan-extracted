use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Math/FFT.pm',
    't/00-compile.t',
    't/apps.t',
    't/fft.t',
    't/lib/MathFftResults.pm',
    't/spctrl.dat',
    't/stats.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Math/Business/BlackScholes/Binaries.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/BlackScholes.t',
    't/barrier_infinity.t',
    't/barrier_zero.t',
    't/get_min_iterations_pelsser.t',
    't/get_stability_constant_pelsser_1997.t',
    't/lib/Roundnear.pm',
    't/min_accuracy_pelsser.t',
    't/negative_rate.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc',
    't/small_value_mu.t',
    't/smalltime.t',
    't/sum_to_one.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

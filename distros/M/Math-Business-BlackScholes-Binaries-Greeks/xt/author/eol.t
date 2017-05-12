use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Math/Business/BlackScholes/Binaries/Greeks.pm',
    'lib/Math/Business/BlackScholes/Binaries/Greeks/Delta.pm',
    'lib/Math/Business/BlackScholes/Binaries/Greeks/Gamma.pm',
    'lib/Math/Business/BlackScholes/Binaries/Greeks/Math.pm',
    'lib/Math/Business/BlackScholes/Binaries/Greeks/Theta.pm',
    'lib/Math/Business/BlackScholes/Binaries/Greeks/Vanna.pm',
    'lib/Math/Business/BlackScholes/Binaries/Greeks/Vega.pm',
    'lib/Math/Business/BlackScholes/Binaries/Greeks/Volga.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Greeks.t',
    't/lib/Roundnear.pm',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Math/GrahamFunction.pm',
    'lib/Math/GrahamFunction/Object.pm',
    'lib/Math/GrahamFunction/SqFacts.pm',
    'lib/Math/GrahamFunction/SqFacts/Dipole.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-results.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

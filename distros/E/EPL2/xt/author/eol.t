use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/EPL2.pm',
    'lib/EPL2/Command.pm',
    'lib/EPL2/Command/A.pm',
    'lib/EPL2/Command/B.pm',
    'lib/EPL2/Command/N.pm',
    'lib/EPL2/Command/O.pm',
    'lib/EPL2/Command/P.pm',
    'lib/EPL2/Command/Q.pm',
    'lib/EPL2/Command/qq.pm',
    'lib/EPL2/Pad.pm',
    'lib/EPL2/Types.pm',
    't/00_EPL2_usage.t',
    't/commands/01_A.t',
    't/commands/02_B.t',
    't/commands/03_O.t',
    't/commands/04_N.t',
    't/commands/05_Q.t',
    't/commands/06_qq.t',
    't/commands/07_P.t',
    't/commands/99_Pad.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

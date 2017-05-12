use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Games/LMSolve.pm',
    'lib/Games/LMSolve/Alice.pm',
    'lib/Games/LMSolve/Base.pm',
    'lib/Games/LMSolve/Input.pm',
    'lib/Games/LMSolve/Minotaur.pm',
    'lib/Games/LMSolve/Numbers.pm',
    'lib/Games/LMSolve/Plank/Base.pm',
    'lib/Games/LMSolve/Plank/Hex.pm',
    'lib/Games/LMSolve/Registry.pm',
    'lib/Games/LMSolve/Tilt/Base.pm',
    'lib/Games/LMSolve/Tilt/Multi.pm',
    'lib/Games/LMSolve/Tilt/RedBlue.pm',
    'lib/Games/LMSolve/Tilt/Single.pm',
    't/00-compile.t',
    't/00use.t',
    't/cpan-changes.t',
    't/planks-bug-fix-1.t',
    't/pod-coverage.t',
    't/pod.t',
    't/regression/regress.sh',
    't/style-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;

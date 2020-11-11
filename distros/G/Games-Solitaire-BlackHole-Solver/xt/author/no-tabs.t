use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/black-hole-solve',
    'bin/golf-solitaire-solve-perl',
    'lib/Games/Solitaire/BlackHole/Solver.pm',
    'lib/Games/Solitaire/BlackHole/Solver/App.pm',
    'lib/Games/Solitaire/BlackHole/Solver/App/Base.pm',
    'lib/Games/Solitaire/BlackHole/Solver/Golf/App.pm',
    't/00-compile.t',
    't/01-run.t',
    't/data/1.bh.board.txt',
    't/data/10.golf.board.txt',
    't/data/26464608654870335080.bh.board.txt',
    't/data/27.bh.board.txt',
    't/data/35.golf.board.txt'
);

notabs_ok($_) foreach @files;
done_testing;

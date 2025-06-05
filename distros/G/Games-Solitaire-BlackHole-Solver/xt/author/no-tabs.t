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
    'lib/Games/Solitaire/BlackHole/Solver/_BoardsStream.pm',
    't/00-compile.t',
    't/01-run.t',
    't/data/1.bh.board.txt',
    't/data/10.golf.board.txt',
    't/data/26464608654870335080.bh.board.txt',
    't/data/27.bh.board.txt',
    't/data/35.golf.board.txt',
    't/data/run-2-to-3-with-3-unsolved/bh2.board',
    't/data/run-2-to-3-with-3-unsolved/bh3.board',
    't/data/run-with-max-iters-2000/bh11.board',
    't/data/run-with-max-iters-2000/bh12.board',
    't/data/run-with-max-iters-2000/bh13.board',
    't/data/run-with-max-iters-2000/bh25.board',
    't/lib/Games/Solitaire/BlackHole/Test.pm'
);

notabs_ok($_) foreach @files;
done_testing;

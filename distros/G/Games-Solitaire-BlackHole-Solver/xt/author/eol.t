use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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
    't/data/35.golf.board.txt',
    't/data/run-2-to-3-with-3-unsolved/bh2.board',
    't/data/run-2-to-3-with-3-unsolved/bh3.board',
    't/data/run-with-max-iters-2000/bh11.board',
    't/data/run-with-max-iters-2000/bh12.board',
    't/data/run-with-max-iters-2000/bh13.board',
    't/data/run-with-max-iters-2000/bh25.board'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

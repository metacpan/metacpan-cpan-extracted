use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Sudoku::Solver',
    AUTHOR              => 'Dr.-Ing. Fritz Mehner <mehner@fh-swf.de>',
    VERSION_FROM        => 'lib/Games/Sudoku/Solver.pm',
    ABSTRACT_FROM       => 'lib/Games/Sudoku/Solver.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Sudoku-Solver-*' },
);

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Games::Sudoku::Kubedoku',
    AUTHOR           => q{Sebastian Isaac Velasco <velascosebastian@gmail.com>},
    VERSION_FROM     => 'lib/Games/Sudoku/Kubedoku.pm',
    ABSTRACT_FROM    => 'lib/Games/Sudoku/Kubedoku.pm',
    LICENSE          => 'GNU',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Games-Sudoku-Kubedoku-*' },
);

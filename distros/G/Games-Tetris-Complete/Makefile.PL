use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Games::Tetris::Complete',
    AUTHOR       => q{Blake Willmarth <bwillmarth@gmail.com>},
    VERSION_FROM => 'lib/Games/Tetris/Complete.pm',
    ABSTRACT     => 'Play Tetris from the console',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    # PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                   => 0,
        'Moose'                        => 0,
        'Moose::Util::TypeConstraints' => 0,
        'Term::ReadKey'                => 0,
        'Time::HiRes'                  => 0,
        'Term::Screen::Uni'            => 0,
        'Thread::Semaphore'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Games-Tetris-Complete-*' },
);

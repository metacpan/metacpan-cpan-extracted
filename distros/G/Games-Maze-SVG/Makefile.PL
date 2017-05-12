use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Maze::SVG',
    AUTHOR              => 'G. Wade Johnson <gwadej@cpan.org>',
    VERSION_FROM        => 'lib/Games/Maze/SVG.pm',
    ABSTRACT_FROM       => 'lib/Games/Maze/SVG.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Games::Maze' => 1.02,
        'Carp' => 0,
    },
    LICENSE             => 'perl',
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gwadej/Games-Maze-SVG.git',
                web  => 'https://github.com/gwadej/Games-Maze-SVG',
            },
        },
    },
    MIN_PERL_VERSION   => 5.006,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Maze-SVG-*' },
    test               => {
        TESTS => 't/*.t xt/*.t',
    },
);

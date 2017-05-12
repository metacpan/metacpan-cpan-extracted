use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Othello',
    AUTHOR              => 'Daniel J. Wright <DWRIGHT@CPAN.ORG>',
    VERSION_FROM        => 'lib/Games/Othello.pm',
    ABSTRACT_FROM       => 'lib/Games/Othello.pm',
    PL_FILES            => {},
    PREREQ_PM => { 'Test::More'       => 0,
                   'Exception::Class' => 1.23,
        },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Othello-*' },
);

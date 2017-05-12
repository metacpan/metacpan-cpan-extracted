# $Id: Makefile.PL,v 1.3 2006/08/22 13:12:28 rousse Exp $

use ExtUtils::MakeMaker;
eval {
    require ExtUtils::MakeMaker::Coverage;
    import ExtUtils::MakeMaker::Coverage;
};

WriteMakefile(
    NAME          => 'Dict::FSA',
    VERSION_FROM  => 'lib/Dict/FSA.pm',
    ABSTRACT_FROM => 'lib/Dict/FSA.pm',
    AUTHOR        => 'Guillaume Rousse <grousse@cpan.org>',
    PREREQ_PM     => {
        'IPC::Open2' => 0,
        'IO::Handle' => 0
    },
    dist           => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean          => {
        FILES => 'Dict-FSA-*'
    },
);

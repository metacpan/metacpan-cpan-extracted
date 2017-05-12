# $Id: Makefile.PL,v 1.5 2006/08/22 13:10:01 rousse Exp $

use ExtUtils::MakeMaker;
eval {
    require ExtUtils::MakeMaker::Coverage;
    import ExtUtils::MakeMaker::Coverage;
};

WriteMakefile(
    NAME          => 'Dict::Lexed',
    VERSION_FROM  => 'lib/Dict/Lexed.pm',
    ABSTRACT_FROM => 'lib/Dict/Lexed.pm',
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
        FILES => 'Dict-Lexed-*'
    },
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ham::Reference::Qsignals',
    AUTHOR              => 'Brad McConahay N8QQ <brad@n8qq.com>',
    VERSION_FROM        => 'lib/Ham/Reference/Qsignals.pm',
    ABSTRACT_FROM       => 'lib/Ham/Reference/Qsignals.pm',
    LICENSE             => 'artistic2',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Ham-Reference-Qsignals-*' },
);

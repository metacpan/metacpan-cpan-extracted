use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IPC::Concurrency',
    AUTHOR              => 'Pawel bbkr Pabian <cpan@bbkr.org>',
    VERSION_FROM        => 'lib/IPC/Concurrency.pm',
    ABSTRACT_FROM       => 'lib/IPC/Concurrency.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'IPC::ShareLite' => 0.13,
        'Test::More' => '0',
        'Test::Exception' => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IPC-Concurrency-*' },
);

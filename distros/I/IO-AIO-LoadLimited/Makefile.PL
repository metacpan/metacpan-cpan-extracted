use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'IO::AIO::LoadLimited',
    AUTHOR           => q{Martin Barth <martin@senfdax.de>},
    VERSION_FROM     => 'lib/IO/AIO/LoadLimited.pm',
    ABSTRACT_FROM    => 'lib/IO/AIO/LoadLimited.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '1.0',
    },
    PREREQ_PM => {
        'IO::AIO'              => '2',
        'common::sense'        => 0,
    },
    dist  => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        PREOP    => 'pod2text lib/IO/AIO/LoadLimited.pm | tee README >$(DISTVNAME)/README;',
    },
    clean => { FILES => 'IO-AIO-LoadLimited-*' },
);

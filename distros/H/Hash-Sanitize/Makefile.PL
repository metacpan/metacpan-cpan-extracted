use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Hash::Sanitize',
    AUTHOR           => q{Horea Gligan <gliganh@gmail.com>},
    VERSION_FROM     => 'lib/Hash/Sanitize.pm',
    ABSTRACT_FROM    => 'lib/Hash/Sanitize.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Exporter'          => 0,
        'Clone'             => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hash-Sanitize-*' },
);

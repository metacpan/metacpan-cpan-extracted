use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'File::ELAN',
    AUTHOR           => q{Simon Cozens <simon@simon-cozens.org>},
    VERSION_FROM     => 'lib/File/ELAN.pm',
    ABSTRACT_FROM    => 'lib/File/ELAN.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        "XML::LibXML" => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-ELAN-*' },
);

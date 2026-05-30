use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Encode::Bijou64',
    AUTHOR           => 'Scott Baker',
    VERSION_FROM     => 'lib/Encode/Bijou64.pm',
    ABSTRACT_FROM    => 'lib/Encode/Bijou64.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.016', # Consistent with example.pl
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Exporter' => '0',
        'strict'   => '0',
        'warnings' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Encode-Bijou64-*' },
);

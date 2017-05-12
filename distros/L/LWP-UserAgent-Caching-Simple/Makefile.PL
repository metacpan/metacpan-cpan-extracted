use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LWP::UserAgent::Caching::Simple',
    AUTHOR           => q{Theo van Hoesel <Th.J.v.Hoesel@THEMA-MEDIA.nl>},
    VERSION_FROM     => 'lib/LWP/UserAgent/Caching/Simple.pm',
    ABSTRACT_FROM    => 'lib/LWP/UserAgent/Caching/Simple.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'           => 0,
    },
    BUILD_REQUIRES => {
        'Test::Most'                    => 0,
        'Test::MockObject'              => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent::Caching'       => 0,
        'CHI'                           => 0,
        'JSON'                          => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LWP-UserAgent-Caching-Simple-*' },
);

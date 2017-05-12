use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LWP::UserAgent::Caching',
    AUTHOR           => q{Theo van Hoesel <Th.J.v.Hoesel@THEMA-MEDIA.nl>},
    VERSION_FROM     => 'lib/LWP/UserAgent/Caching.pm',
    ABSTRACT_FROM    => 'lib/LWP/UserAgent/Caching.pm',
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
        'LWP::UserAgent'                => 0,
        'HTTP::Caching'                 => 0,
        'HTTP::Request::Common'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-Caching-*' },
);

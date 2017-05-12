use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'IHeartRadio::Streams',
    AUTHOR           => q{Jim Turner <turnerjw784@yahoo.com>},
    VERSION_FROM     => 'lib/IHeartRadio/Streams.pm',
    ABSTRACT_FROM    => 'lib/IHeartRadio/Streams.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::Simple'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IHeartRadio-Streams-*' },
);

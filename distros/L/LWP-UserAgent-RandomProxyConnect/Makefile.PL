use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LWP::UserAgent::RandomProxyConnect',
    AUTHOR           => q{Hector Valverde <hvalverde@uma.es>},
    VERSION_FROM     => 'lib/LWP/UserAgent/RandomProxyConnect.pm',
    ABSTRACT_FROM    => 'lib/LWP/UserAgent/RandomProxyConnect.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LWP-UserAgent-RandomProxyConnect-*' },
);

use 5.026;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Device::Yeelight',
    AUTHOR           => q{Jan Baier <jan.baier@amagical.net>},
    VERSION_FROM     => 'lib/Device/Yeelight.pm',
    ABSTRACT_FROM    => 'lib/Device/Yeelight.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.026',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'JSON'                  => 2.97,
        'IO'                    => 1.38,
        'IO::Socket::Multicast' => 1.12,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Device-Yeelight-*' },
);

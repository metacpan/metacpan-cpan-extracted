use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Device::TPLink',
    AUTHOR           => q{Verlin Henderson <verlin@gmail.com>},
    VERSION_FROM     => 'lib/Device/TPLink.pm',
    ABSTRACT_FROM    => 'lib/Device/TPLink.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'JSON' => '0',
        'LWP::JSON::Tiny' => '0',
        'Moose' => '0',
        'UUID::Generator::PurePerl' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Device-TPLink-*' },
);

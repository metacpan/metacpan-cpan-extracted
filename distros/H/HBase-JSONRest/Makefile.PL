use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HBase::JSONRest',
    AUTHOR           => q{Bosko Devetak <bosko.devetak@gmail.com>},
    VERSION_FROM     => 'lib/HBase/JSONRest.pm',
    ABSTRACT_FROM    => 'lib/HBase/JSONRest.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'  => 0,
        'Test::Fatal' => 0,
    },
    PREREQ_PM => {
        'HTTP::Tiny'   => 0,
        'URI::Escape'  => 0,
        'MIME::Base64' => 0,
        'JSON::XS'     => 0,
        'Time::HiRes'  => 0,
        'Data::Dumper' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HBase-JSONRest-*' },
);

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'JSON::JSend',
    AUTHOR           => q{Hoe-Kit Chew <hoekit at gmail dot com>},
    VERSION_FROM     => 'lib/JSON/JSend.pm',
    ABSTRACT_FROM    => 'lib/JSON/JSend.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'JSON' => 0,
    },
    PREREQ_PM => {
        'JSON' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'JSON-JSend-*' },
);

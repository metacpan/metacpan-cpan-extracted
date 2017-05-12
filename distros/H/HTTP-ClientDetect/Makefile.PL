use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTTP::ClientDetect',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/HTTP/ClientDetect.pm',
    ABSTRACT_FROM    => 'lib/HTTP/ClientDetect.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Moo' => 0,
        'Geo::IP::PurePerl' => 0, # but Geo::IP will do OK too
    },
    PREREQ_PM => {
        'Locale::Language' => 0,
        'Locale::Country' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-ClientDetect-*' },
);

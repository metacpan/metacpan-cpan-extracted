use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'InfluxDB::HTTP',
    AUTHOR           => q{Raphael Seebacher <raphael@seebachers.ch>},
    VERSION_FROM     => 'lib/InfluxDB/HTTP.pm',
    ABSTRACT_FROM    => 'lib/InfluxDB/HTTP.pm',
    LICENSE          => 'perl_5',
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
    clean => { FILES => 'InfluxDB-HTTP-*' },
);

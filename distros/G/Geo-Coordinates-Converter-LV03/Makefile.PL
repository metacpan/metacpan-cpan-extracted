use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::Coordinates::Converter::LV03',
    AUTHOR           => q{René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>},
    VERSION_FROM     => 'lib/Geo/Coordinates/Converter/LV03.pm',
    ABSTRACT_FROM    => 'lib/Geo/Coordinates/Converter/LV03.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Simple' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-Coordinates-Converter-LV03-*' },
);

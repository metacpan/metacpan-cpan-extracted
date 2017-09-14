#!/usr/bin/perl
use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::OSM::Render',
    AUTHOR           => q{René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>},
    VERSION_FROM     => 'lib/Geo/OSM/Render.pm',
    ABSTRACT_FROM    => 'lib/Geo/OSM/Render.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
         'SVG'                              => 0,
         'Geo::OSM::Primitive::Node'        => 0,
         'Geo::OSM::Primitive::Way'         => 0,
    },
    TEST_REQUIRES => {
        'Test::Simple'                      => 0,
        'Test::More'                        => 0,
        'Test::File'                        => 0,
        'Geo::Coordinates::Converter::LV03' => 0.02,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-OSM-Render-*' },
);

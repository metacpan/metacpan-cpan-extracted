#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::NYC',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/NYC.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/NYC.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => '0.13',
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'File::ShareDir'       => '1.114',
        'Map::Tube'            => '3.63',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-NYC-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::NYC'                           => { file => 'lib/Map/Tube/NYC.pm'                        , version => '0.68' },
            'Map::Tube::NYC::Line::INDSixthAvenue'     => { file => 'lib/Map/Tube/NYC/Line/INDSixthAvenue.pm'    , version => '0.68' },
            'Map::Tube::NYC::Line::INDEighthAvenue'    => { file => 'lib/Map/Tube/NYC/Line/INDEighthAvenue.pm'   , version => '0.68' },
            'Map::Tube::NYC::Line::INDCrosstown'       => { file => 'lib/Map/Tube/NYC/Line/INDCrosstown.pm'      , version => '0.68' },
            'Map::Tube::NYC::Line::IRTFlushing'        => { file => 'lib/Map/Tube/NYC/Line/IRTFlushing.pm'       , version => '0.68' },
            'Map::Tube::NYC::Line::BMTCanarsie'        => { file => 'lib/Map/Tube/NYC/Line/BMTCanarsie.pm'       , version => '0.68' },
            'Map::Tube::NYC::Line::BMTNassauStreet'    => { file => 'lib/Map/Tube/NYC/Line/BMTNassauStreet.pm'   , version => '0.68' },
            'Map::Tube::NYC::Line::IRTLexingtonAvenue' => { file => 'lib/Map/Tube/NYC/Line/IRTLexingtonAvenue.pm', version => '0.68' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-NYC.git',
                web  => 'https://github.com/manwar/Map-Tube-NYC',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

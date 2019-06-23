#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::Barcelona',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Barcelona.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Barcelona.pm',
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
    clean => { FILES => 'Map-Tube-Barcelona-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Barcelona'            => { file => 'lib/Map/Tube/Barcelona.pm',          version => '0.73' },
            'Map::Tube::Barcelona::Line::L1'  => { file => 'lib/Map/Tube/Barcelona/Line/L1.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L2'  => { file => 'lib/Map/Tube/Barcelona/Line/L2.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L3'  => { file => 'lib/Map/Tube/Barcelona/Line/L3.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L4'  => { file => 'lib/Map/Tube/Barcelona/Line/L4.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L5'  => { file => 'lib/Map/Tube/Barcelona/Line/L5.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L6'  => { file => 'lib/Map/Tube/Barcelona/Line/L6.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L7'  => { file => 'lib/Map/Tube/Barcelona/Line/L7.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L8'  => { file => 'lib/Map/Tube/Barcelona/Line/L8.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L9'  => { file => 'lib/Map/Tube/Barcelona/Line/L9.pm',  version => '0.73' },
            'Map::Tube::Barcelona::Line::L10' => { file => 'lib/Map/Tube/Barcelona/Line/L10.pm', version => '0.73' },
            'Map::Tube::Barcelona::Line::L11' => { file => 'lib/Map/Tube/Barcelona/Line/L11.pm', version => '0.73' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Barcelona.git',
                web  => 'https://github.com/manwar/Map-Tube-Barcelona',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

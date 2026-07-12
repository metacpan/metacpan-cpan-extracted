#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::London',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/London.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/London.pm',
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
        'version'              => '0.77',
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'File::ShareDir'       => '1.114',
        'Map::Tube'            => '5.1.0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-London-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::London' => {
                file    => 'lib/Map/Tube/London.pm',
                version => MM->parse_version('lib/Map/Tube/London.pm')
            },
            'Map::Tube::London::Line::Bakerloo' => {
                file    => 'lib/Map/Tube/London/Line/Bakerloo.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Bakerloo.pm')
            },
            'Map::Tube::London::Line::Central' => {
                file    => 'lib/Map/Tube/London/Line/Central.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Central.pm')
            },
            'Map::Tube::London::Line::Circle' => {
                file    => 'lib/Map/Tube/London/Line/Circle.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Circle.pm')
            },
            'Map::Tube::London::Line::District' => {
                file    => 'lib/Map/Tube/London/Line/District.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/District.pm')
            },
            'Map::Tube::London::Line::DLR' => {
                file    => 'lib/Map/Tube/London/Line/DLR.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/DLR.pm')
            },
            'Map::Tube::London::Line::HammersmithCity' => {
                file    => 'lib/Map/Tube/London/Line/HammersmithCity.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/HammersmithCity.pm')
            },
            'Map::Tube::London::Line::Jubilee' => {
                file    => 'lib/Map/Tube/London/Line/Jubilee.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Jubilee.pm')
            },
            'Map::Tube::London::Line::Metropolitan' => {
                file    => 'lib/Map/Tube/London/Line/Metropolitan.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Metropolitan.pm')
            },
            'Map::Tube::London::Line::Northern' => {
                file    => 'lib/Map/Tube/London/Line/Northern.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Northern.pm')
            },
            'Map::Tube::London::Line::Overground' => {
                file    => 'lib/Map/Tube/London/Line/Overground.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Overground.pm')
            },
            'Map::Tube::London::Line::Piccadilly' => {
                file    => 'lib/Map/Tube/London/Line/Piccadilly.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Piccadilly.pm')
            },
            'Map::Tube::London::Line::Victoria' => {
                file    => 'lib/Map/Tube/London/Line/Victoria.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/Victoria.pm')
            },
            'Map::Tube::London::Line::WaterlooCity' => {
                file    => 'lib/Map/Tube/London/Line/WaterlooCity.pm',
                version => MM->parse_version('lib/Map/Tube/London/Line/WaterlooCity.pm')
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-London.git',
                web  => 'https://github.com/manwar/Map-Tube-London',
            },
             bugtracker => {
                web     => 'https://github.com/manwar/Map-Tube-London/issues'
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

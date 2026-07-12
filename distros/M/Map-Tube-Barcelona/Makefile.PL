#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::Barcelona',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
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
        'Map::Tube'            => '5.1.0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-Barcelona-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Barcelona' => {
                file    => 'lib/Map/Tube/London/Barcelona.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona.pm')
            },
            'Map::Tube::Barcelona::Line::L1' => {
                file    => 'lib/Map/Tube/London/Barcelona/L1.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L1.pm')
            },
            'Map::Tube::Barcelona::Line::L2' => {
                file    => 'lib/Map/Tube/London/Barcelona/L2.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L2.pm')
            },
            'Map::Tube::Barcelona::Line::L3' => {
                file    => 'lib/Map/Tube/London/Barcelona/L3.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L3.pm')
            },
            'Map::Tube::Barcelona::Line::L4' => {
                file    => 'lib/Map/Tube/London/Barcelona/L4.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L4.pm')
            },
            'Map::Tube::Barcelona::Line::L5' => {
                file    => 'lib/Map/Tube/London/Barcelona/L5.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L5.pm')
            },
            'Map::Tube::Barcelona::Line::L6' => {
                file    => 'lib/Map/Tube/London/Barcelona/L6.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L6.pm')
            },
            'Map::Tube::Barcelona::Line::L7' => {
                file    => 'lib/Map/Tube/London/Barcelona/L7.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L7.pm')
            },
            'Map::Tube::Barcelona::Line::L8' => {
                file    => 'lib/Map/Tube/London/Barcelona/L8.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L8.pm')
            },
            'Map::Tube::Barcelona::Line::L9' => {
                file    => 'lib/Map/Tube/London/Barcelona/L9.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L9.pm')
            },
            'Map::Tube::Barcelona::Line::L10' => {
                file    => 'lib/Map/Tube/London/Barcelona/L10.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L10.pm')
            },
            'Map::Tube::Barcelona::Line::L11' => {
                file    => 'lib/Map/Tube/London/Barcelona/L11.pm',
                version => MM->parse_version('lib/Map/Tube/Barcelona/Line/L11.pm')
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Barcelona.git',
                web  => 'https://github.com/manwar/Map-Tube-Barcelona',
            },
            bugtracker => {
                web  => 'https://github.com/manwar/Map-Tube-Barcelona/issues'
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

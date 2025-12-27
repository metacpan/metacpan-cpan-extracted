#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::Sydney',
    AUTHOR             => q{Peter Harrison <pete@28smith.com>},
    VERSION_FROM       => 'lib/Map/Tube/Sydney.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Sydney.pm',
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
        'Map::Tube'            => '4.07',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-Sydney-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Sydney'           => { file => 'lib/Map/Tube/Sydney.pm',         version => '1.00' },
            'Map::Tube::Sydney::Line::T1' => { file => 'lib/Map/Tube/Sydney/Line/T1.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T2' => { file => 'lib/Map/Tube/Sydney/Line/T2.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T3' => { file => 'lib/Map/Tube/Sydney/Line/T3.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T4' => { file => 'lib/Map/Tube/Sydney/Line/T4.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T5' => { file => 'lib/Map/Tube/Sydney/Line/T5.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T6' => { file => 'lib/Map/Tube/Sydney/Line/T6.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T7' => { file => 'lib/Map/Tube/Sydney/Line/T7.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T8' => { file => 'lib/Map/Tube/Sydney/Line/T8.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::T9' => { file => 'lib/Map/Tube/Sydney/Line/T9.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::M1' => { file => 'lib/Map/Tube/Sydney/Line/M1.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::L1' => { file => 'lib/Map/Tube/Sydney/Line/L1.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::L2' => { file => 'lib/Map/Tube/Sydney/Line/L2.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::L3' => { file => 'lib/Map/Tube/Sydney/Line/L3.pm', version => '1.00' },
            'Map::Tube::Sydney::Line::L4' => { file => 'lib/Map/Tube/Sydney/Line/L4.pm', version => '1.00' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/earlybean4/Map-Tube-Sydney.git',
                web  => 'https://github.com/earlybean4/Map-Tube-Sydney',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

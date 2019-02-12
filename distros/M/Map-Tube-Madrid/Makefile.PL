#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::Madrid',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Madrid.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Madrid.pm',
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
        'Map::Tube'            => '3.59',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-Madrid-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Madrid'            => { file => 'lib/Map/Tube/Madrid.pm'        ,  version => '0.29' },
            'Map::Tube::Madrid::Line::L1'  => { file => 'lib/Map/Tube/Madrid/Line/L1.pm',  version => '0.29' },
            'Map::Tube::Madrid::Line::L2'  => { file => 'lib/Map/Tube/Madrid/Line/L2.pm',  version => '0.29' },
            'Map::Tube::Madrid::Line::L3'  => { file => 'lib/Map/Tube/Madrid/Line/L3.pm',  version => '0.29' },
            'Map::Tube::Madrid::Line::L5'  => { file => 'lib/Map/Tube/Madrid/Line/L5.pm',  version => '0.29' },
            'Map::Tube::Madrid::Line::L11' => { file => 'lib/Map/Tube/Madrid/Line/L11.pm', version => '0.29' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Madrid.git',
                web  => 'https://github.com/manwar/Map-Tube-Madrid',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

#!/usr/bin/perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::Leipzig',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Leipzig.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Leipzig.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
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
        'Map::Tube'            => '4.09',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-Leipzig-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Leipzig'           => { file => 'lib/Map/Tube/Leipzig.pm'        , version => '0.03' },
            'Map::Tube::Leipzig::Line::S3' => { file => 'lib/Map/Tube/Leipzig/Line/S3.pm', version => '0.03' },
            'Map::Tube::Leipzig::Line::S7' => { file => 'lib/Map/Tube/Leipzig/Line/S7.pm', version => '0.03' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Leipzig.git',
                web  => 'https://github.com/manwar/Map-Tube-Leipzig',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

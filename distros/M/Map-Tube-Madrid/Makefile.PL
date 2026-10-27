#!/usr/bin/perl

use v5.14.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::Madrid',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Madrid.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Madrid.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => '0.13',
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
        'Path::Tiny' => 0.146,
    },
    PREREQ_PM => {
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'File::ShareDir'       => '1.114',
        'Map::Tube'            => '4.09',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t xt/*.t' },
    clean => { FILES => 'Map-Tube-Madrid-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Madrid' => {
                file    => 'lib/Map/Tube/Madrid.pm',
                version => MM->parse_version('lib/Map/Tube/Madrid.pm')
            },
        },
        prereqs => {
            test => {
                recommends => {
                    'CPAN::Meta'          => 0,
                    'Test::CheckManifest' => 0,
                    'Test::Map:::Tube'    => 4.09,
                    'Test::Pod'           => 1.22,
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Madrid.git',
                web  => 'https://github.com/manwar/Map-Tube-Madrid',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/Map-Tube-Madrid/issues'
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Map::Tube::Plugin::Formatter',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Plugin/Formatter.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Plugin/Formatter.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM                  => {
        'YAML'                 => '0.84',
        'JSON'                 => '2.53',
        'XML::Twig'            => '3.48',
        'Moo::Role'            => '2.000000',
        'namespace::clean'     => '0.24',
        'Map::Tube::Exception' => '3.12',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-Plugin-Formatter-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Plugin::Formatter'        => { file => 'lib/Map/Tube/Plugin/Formatter.pm',       version => '0.14' },
            'Map::Tube::Plugin::Formatter::Utils' => { file => 'lib/Map/Tube/Plugin/Formatter/Utils.pm', version => '0.14' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Plugin-Formatter.git',
                web  => 'https://github.com/manwar/Map-Tube-Plugin-Formatter',
            },
        }})
     : ()
    ),
);

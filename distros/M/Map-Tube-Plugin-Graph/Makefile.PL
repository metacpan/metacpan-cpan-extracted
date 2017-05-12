#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Map::Tube::Plugin::Graph',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Plugin/Graph.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Plugin/Graph.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM                  => {
        'Moo::Role'            => '2.000000',
        'namespace::clean'     => '0.24',
        'GraphViz2'            => '2.34',
        'File::Temp'           => '0.2304',
        'MIME::Base64'         => '3.14',
        'Graphics::ColorNames' => '2.11',
        'Map::Tube::Exception' => '3.08',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-Plugin-Graph-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Plugin::Graph'        => { file => 'lib/Map/Tube/Plugin/Graph.pm',       version => '0.24' },
            'Map::Tube::Plugin::Graph::Utils' => { file => 'lib/Map/Tube/Plugin/Graph/Utils.pm', version => '0.24' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Plugin-Graph.git',
                web  => 'https://github.com/manwar/Map-Tube-Plugin-Graph',
            },
        }})
     : ()
    ),
);

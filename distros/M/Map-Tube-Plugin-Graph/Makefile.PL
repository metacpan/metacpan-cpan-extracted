#!/usr/bin/perl

use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Map::Tube::Plugin::Graph',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Plugin/Graph.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Plugin/Graph.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
        'Test::Lib'  => 0,
    },
    PREREQ_PM                  => {
        'Moo::Role'            => '2.000000',
        'namespace::autoclean' => '0.28',
        'File::Which'          => '1.21',
        'GraphViz2'            => '2.63',
        'IPC::Run3'            => '0.048',
        'MIME::Base64'         => '3.14',
        'Map::Tube'            => '5.1.0',
        'Map::Tube::Exception' => '3.18',
        'Graph'                => '0.9732',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t xt/*.t' },
    clean => { FILES => 'Map-Tube-Plugin-Graph-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Plugin::Graph' => {
                file    => 'lib/Map/Tube/Plugin/Graph.pm',
                version => MM->parse_version('lib/Map/Tube/Plugin/Graph.pm')
            },
            'Map::Tube::Plugin::Graph::Utils' => {
                file    => 'lib/Map/Tube/Plugin/Graph/Utils.pm',
                version => MM->parse_version('lib/Map/Tube/Plugin/Graph/Utils.pm')
            },
        },
        prereqs => {
            test => {
                recommends => {
                    'Test::CPAN::Changes'    => 0,
                    'Test::CPAN::Meta::JSON' => 0,
                    'Test::CPAN::Meta'       => 0,
                    'Test::Pod'              => 1.22,
                    'Test::Version'          => 0,
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Plugin-Graph.git',
                web  => 'https://github.com/manwar/Map-Tube-Plugin-Graph',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/Map-Tube-Plugin-Graph/issues'
            },
        },
    },
);

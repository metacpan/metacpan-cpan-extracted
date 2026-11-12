#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Map::Tube::CLI',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/CLI.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/CLI.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/map-tube' ],
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES      => {
        'Capture::Tiny' => '0.28',
        'CPAN::Meta'    => 0,
        'File::Find'    => 0,
        'Test::More'    => 0,
    },
    PREREQ_PM                  => {
        'Map::Tube::Exception' => '3.25',
        'Map::Tube'            => '5.1.0',
        'Map::Tube::Generic'   => '0.2.1',
        'Moo'                  => '2.000000',
        'MooX::Options'        => '4.023',
        'namespace::autoclean' => '0.28',
        'Text::ASCIITable'     => '0.22',
        'Try::Tiny'            => 0,
        'Types::Standard'      => '1.000005',
        'utf8::all'            => '0.024',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t' },
    clean => { FILES => 'Map-Tube-CLI-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    'Unicode::Collate'             => 0,
                    'Map::Tube::Plugin::FuzzyFind' => '0.80.0',
                    'Map::Tube::Plugin::Graph'     => '1.3.0',
                },
            },
            test => {
                recommends => {
                    'Test::CPAN::Changes' => 0,
                    'Test::CheckManifest' => 0,
                    'Test::Pod'           => 1.22,
                    'Test::Version'       => 0,
                },
            },
        },
        provides    => {
            'Map::Tube::CLI' => {
                file    => 'lib/Map/Tube/CLI.pm',
                version => MM->parse_version('lib/Map/Tube/CLI.pm')
            },
            'Map::Tube::CLI::Option' => {
                file    => 'lib/Map/Tube/CLI/Option.pm',
                version => MM->parse_version('lib/Map/Tube/CLI/Option.pm')
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-CLI.git',
                web  => 'https://github.com/manwar/Map-Tube-CLI',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/Map-Tube-CLI/issues'
            },
        }})
     : ()
    ),
);

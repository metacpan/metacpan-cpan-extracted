#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/map-data-converter' ],
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => '0.13',
    },
    BUILD_REQUIRES => {
        'Test::Lib'       => 0,
        'Test::More'      => '1.001014',
        'Test::Exception' => 0,
        'Graph'           => 0,
    },
    PREREQ_PM                  => {
        'version'              => '0.77',
        'overload'             => 0,
        'Throwable'            => 0,
        'Moo'                  => '2.000000',
        'Moo::Role'            => '2.000000',
        'Role::Tiny'           => '2.000000',
        'MooX::Options'        => '4.023',
        'namespace::autoclean' => '0.28',
        'JSON::MaybeXS'        => 0,
        'File::Basename'       => '2.6',
        'XML::Twig'            => '3.48',
        'XML::Parser'          => '2.23',
        'Module::Pluggable'    => '5.1',
        'Map::Tube::Exception' => '3.24',
        'Type::Tiny'           => '1.000005',
        'File::ShareDir'       => '1.114',
        'Try::Tiny'            => 0,
        'Scalar::Util'         => 0,
        'Unicode::Normalize'   => 0,
        'Data::Compare'        => '1.25',
        'Map::Tube::Plugin::Formatter' => '0.16',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t xt/*.t t/test-the-test/*.t' },
    clean => { FILES => 'Map-Tube-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube' => {
                file    => 'lib/Map/Tube.pm',
                version => MM->parse_version('lib/Map/Tube.pm')
            },
            'Map::Tube::Node' => {
                file    => 'lib/Map/Tube/Node.pm',
                version => MM->parse_version('lib/Map/Tube/Node.pm')
            },
            'Map::Tube::Line' => {
                file    => 'lib/Map/Tube/Line.pm',
                version => MM->parse_version('lib/Map/Tube/Line.pm')
            },
            'Map::Tube::Table' => {
                file    => 'lib/Map/Tube/Table.pm',
                version => MM->parse_version('lib/Map/Tube/Table.pm')
            },
            'Map::Tube::Route' => {
                file    => 'lib/Map/Tube/Route.pm',
                version => MM->parse_version('lib/Map/Tube/Route.pm')
            },
            'Map::Tube::Utils' => {
                file    => 'lib/Map/Tube/Utils.pm',
                version => MM->parse_version('lib/Map/Tube/Utils.pm')
            },
            'Map::Tube::Types' => {
                file    => 'lib/Map/Tube/Types.pm',
                version => MM->parse_version('lib/Map/Tube/Types.pm')
            },
            'Map::Tube::Cookbook' => {
                file    => 'lib/Map/Tube/Cookbook.pm',
                version => MM->parse_version('lib/Map/Tube/Cookbook.pm')
            },
            'Map::Tube::Pluggable' => {
                file    => 'lib/Map/Tube/Pluggable.pm',
                version => MM->parse_version('lib/Map/Tube/Pluggable.pm')
            },
            'Test::Map::Tube' => {
                file    => 'lib/Test/Map/Tube.pm',
                version => MM->parse_version('lib/Test/Map/Tube.pm')
            },
        },
        prereqs => {
            test => {
                recommends => {
                    'Graph'                  => 0,
                    'Test::CheckManifest'    => 0,
                    'Test::CPAN::Changes'    => 0,
                    'Test::CPAN::Meta'       => 0,
                    'Test::CPAN::Meta::JSON' => 0,
                    'Test::Kwalitee'         => 0,
                    'Test::Pod'              => 1.22,
                    'Test::Pod::Coverage'    => 1.00,
                    'Test::Version'          => 0,
                    'Test::Lib'              => 0,
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube.git',
                web  => 'https://github.com/manwar/Map-Tube',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/Map-Tube/issues'
            },
        },
    },
);

package MY;
use File::ShareDir::Install 'postamble';

#!/usr/bin/perl

use 5.006;
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
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => '0.13',
    },
    BUILD_REQUIRES => {
        'Test::More'      => '1.001014',
        'Test::Exception' => 0,
    },
    PREREQ_PM                  => {
        'overload'             => 0,
        'Throwable'            => 0,
        'Moo'                  => '2.000000',
        'Moo::Role'            => '2.000000',
        'Role::Tiny'           => '2.000000',
        'MooX::Options'        => '4.023',
        'namespace::autoclean' => '0.28',
        'JSON'                 => '2.90',
        'File::Basename'       => '2.6',
        'XML::Twig'            => '3.48',
        'XML::Parser'          => '2.23',
        'Module::Pluggable'    => '5.1',
        'Map::Tube::Exception' => '3.24',
        'Type::Tiny'           => '1.000005',
        'File::ShareDir'       => '1.114',
        'Taint::Util'          => '0.08',
        'Data::Compare'        => '1.25',
        'Map::Tube::Plugin::Formatter' => '0.16',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube'            => { file => 'lib/Map/Tube.pm'          , version => '3.94' },
            'Map::Tube::Node'      => { file => 'lib/Map/Tube/Node.pm'     , version => '3.94' },
            'Map::Tube::Line'      => { file => 'lib/Map/Tube/Line.pm'     , version => '3.94' },
            'Map::Tube::Table'     => { file => 'lib/Map/Tube/Table.pm'    , version => '3.94' },
            'Map::Tube::Route'     => { file => 'lib/Map/Tube/Route.pm'    , version => '3.94' },
            'Map::Tube::Utils'     => { file => 'lib/Map/Tube/Utils.pm'    , version => '3.94' },
            'Map::Tube::Types'     => { file => 'lib/Map/Tube/Types.pm'    , version => '3.94' },
            'Map::Tube::Cookbook'  => { file => 'lib/Map/Tube/Cookbook.pm' , version => '3.94' },
            'Map::Tube::Pluggable' => { file => 'lib/Map/Tube/Pluggable.pm', version => '3.94' },
            'Test::Map::Tube'      => { file => 'lib/Test/Map/Tube.pm'     , version => '3.94' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube.git',
                web  => 'https://github.com/manwar/Map-Tube',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';

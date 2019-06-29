#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Map::Tube::CLI',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/CLI.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/CLI.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/map-tube' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES      => {
        'Test::More'    => 0,
        'Capture::Tiny' => '0.28',
    },
    PREREQ_PM                  => {
        'Types::Standard'      => '1.000005',
        'MooX::Options'        => '4.023',
        'Module::Pluggable'    => '5.1',
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'MIME::Base64'         => '3.14',
        'Map::Tube::Exception' => '3.17',
        'Map::Tube'            => '3.63',
        'Encode::Locale'       => '1.05',
        'Text::ASCIITable'     => '0.22',
        'utf8::all'            => '0.024',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Map-Tube-CLI-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::CLI'         => { file => 'lib/Map/Tube/CLI.pm'       , version => '0.64' },
            'Map::Tube::CLI::Option' => { file => 'lib/Map/Tube/CLI/Option.pm', version => '0.64' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-CLI.git',
                web  => 'https://github.com/manwar/Map-Tube-CLI',
            },
        }})
     : ()
    ),
);

#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Games::Domino',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Games/Domino.pm',
    ABSTRACT_FROM      => 'lib/Games/Domino.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/play-domino' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Attribute::Memoize'      => '1.01',
        'List::Util'              => '1.19',
        'Term::ANSIColor::Markup' => '0.06',
        'Moo'                     => '2.000000',
        'namespace::autoclean'    => '0.28',
        'overload'                => 0,
        'Type::Tiny'              => '1.000005',
        'Term::ReadKey'           => '2.33',
        'Term::Screen::Lite'      => '0.03',
        'MooX::Options'           => '4.023',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Games-Domino-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Games::Domino'         => { file => 'lib/Games/Domino.pm'       , version => '0.32' },
            'Games::Domino::Player' => { file => 'lib/Games/Domino/Player.pm', version => '0.32' },
            'Games::Domino::Tile'   => { file => 'lib/Games/Domino/Tile.pm'  , version => '0.32' },
            'Games::Domino::Params' => { file => 'lib/Games/Domino/Params.pm', version => '0.32' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Games-Domino.git',
                web  => 'https://github.com/manwar/Games-Domino',
            },
        }})
     : ()
    ),
);

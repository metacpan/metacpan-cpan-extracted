#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Games::TicTacToe',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Games/TicTacToe.pm',
    ABSTRACT_FROM      => 'lib/Games/TicTacToe.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/play-tictactoe' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Warn' => 0,
    },
    PREREQ_PM => {
        'Moo'                     => '2.000000',
        'namespace::clean'        => '0.24',
        'MooX::Options'           => '4.023',
        'Term::ANSIColor::Markup' => '0.06',
        'Type::Tiny'              => '1.000005',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Games-TicTacToe-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Games::TicTacToe'         => { file => 'lib/Games/TicTacToe.pm',        version => '0.24' },
            'Games::TicTacToe::Board'  => { file => 'lib/Games/TicTacToe/Board.pm',  version => '0.24' },
            'Games::TicTacToe::Move'   => { file => 'lib/Games/TicTacToe/Move.pm',   version => '0.24' },
            'Games::TicTacToe::Params' => { file => 'lib/Games/TicTacToe/Params.pm', version => '0.24' },
            'Games::TicTacToe::Player' => { file => 'lib/Games/TicTacToe/Player.pm', version => '0.24' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Games-TicTacToe.git',
                web  => 'https://github.com/manwar/Games-TicTacToe',
            },
        }})
     : ()
    ),
);

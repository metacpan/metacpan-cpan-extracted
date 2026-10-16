use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Game::Terminal',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Game/Terminal.pm',
    ABSTRACT_FROM    => 'lib/Game/Terminal.pm',
    LICENSE          => 'artistic_2',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    EXE_FILES        => [ 'bin/game' ],
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.05',
        'Game::Terminal::Kit'  => '0.05',
        'Game::Backgammon'     => '0.04',
        'Game::Brandubh'       => '0.03',
        'Game::Checkers'       => '0.04',
        'Game::Cribbage'       => '0.18',
        'Game::Dominoes'       => '0.04',
        'Game::Durak'          => '0.04',
        'Game::Fanorona'       => '0.03',
        'Game::Floppy'         => '0.10',
        'Game::Gin'            => '0.04',
        'Game::Go'             => '0.04',
        'Game::Mahjong'        => '0.04',
        'Game::Merrills'       => '0.03',
        'Game::Oware'          => '0.04',
        'Game::Reversi'        => '0.04',
        'Game::RoyalUr'        => '0.03',
        'Game::Schnapsen'      => '0.04',
        'Game::Shogi'          => '0.01',
        'Game::Snake'          => '0.13',
        'Game::Sternhalma'     => '0.01',
        'Game::Xiangqi'        => '0.05',
        'Term::Chess'          => '0.03',
        'Term::Maze'           => '0.06',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    'Term::ReadKey' => '0',
                },
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Terminal-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

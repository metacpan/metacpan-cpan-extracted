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
        'Game::Backgammon'     => '0.03',
        'Game::Brandubh'       => '0.02',
        'Game::Checkers'       => '0.03',
        'Game::Cribbage'       => '0.17',
        'Game::Dominoes'       => '0.03',
        'Game::Durak'          => '0.03',
        'Game::Fanorona'       => '0.02',
        'Game::Floppy'         => '0.09',
        'Game::Gin'            => '0.03',
        'Game::Go'             => '0.03',
        'Game::Mahjong'        => '0.03',
        'Game::Merrills'       => '0.02',
        'Game::Oware'          => '0.03',
        'Game::Reversi'        => '0.03',
        'Game::RoyalUr'        => '0.02',
        'Game::Schnapsen'      => '0.03',
        'Game::Snake'          => '0.12',
        'Game::Xiangqi'        => '0.04',
        'Term::Chess'          => '0.01',
        'Term::Maze'           => '0.05',
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

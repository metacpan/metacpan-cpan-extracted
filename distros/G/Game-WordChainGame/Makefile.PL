use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Game::WordChainGame',
    AUTHOR             => q{Rohit R Manjrekar <manjrekarrohit76@gmail.com>},
    VERSION_FROM       => 'lib/Game/WordChainGame.pm',
    ABSTRACT_FROM      => 'lib/Game/WordChainGame.pm', 
    MIN_PERL_VERSION   => 5.006,
    LICENSE            => 'mit',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM     => {
        'Moose'               => 0,
        'WordNet::QueryData'  => 0,
    },
    TEST_REQUIRES => {
        'Test::More'        => 0,
    },
    "test" => {
        "TESTS" => "t/*.t"
    },
    META_MERGE => {
        "meta-spec" => { version => 1.0 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/rmanjrekar/Games.git',
                web  => 'https://github.com/rmanjrekar/Games',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-WordChainGame-*' },
);

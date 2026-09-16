use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Game::Dominoes',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Game/Dominoes.pm',
    ABSTRACT_FROM    => 'lib/Game/Dominoes.pm',
    LICENSE          => 'artistic_2',
    EXE_FILES        => [ 'bin/dominoes' ],
    # 5.010 is the SYNTACTIC floor, and it is a fact rather than a guess: the
    # defined-or operator is used in Game::Dominoes, ::Error, ::Result, ::Bot
    # and ::Terminal, and nothing later than that appears anywhere. No say, no
    # state, no signatures, no postfix dereference. Object::Proto::Sugar, the
    # one runtime dependency, declares 5.008003, so it does not raise this.
    #
    # The suite has actually been RUN on 5.34.1 and 5.42.0, both clean. The
    # span from 5.10 to 5.32 is inferred from the syntax and not tested, and
    # saying so is the point: Module::Starter's stock 5.008003 is a number
    # nobody ever checked, and this one should not become another.
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    # One runtime dependency. Digest::SHA is core and does not go here.
    # A second one needs a reason written down.
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Dominoes-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

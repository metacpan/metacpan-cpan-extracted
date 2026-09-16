use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Game::Reversi',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Game/Reversi.pm',
    ABSTRACT_FROM    => 'lib/Game/Reversi.pm',
    LICENSE          => 'artistic_2',
    EXE_FILES        => [ 'bin/reversi' ],
    # THE FLOOR, AND WHAT IS EVIDENCE FOR IT.
    #
    # 5.010 is the SYNTACTIC floor and it is a fact rather than a guess: the
    # defined-or operator is used throughout, and nothing later than that
    # appears anywhere. No say, no state, no signatures, no postfix dereference,
    # no // = , no lexical subs. Object::Proto::Sugar, the one runtime
    # dependency, declares 5.008003, so it does not raise this.
    #
    # THE WHOLE SUITE HAS ACTUALLY BEEN RUN, and passed, on:
    #
    #     perl 5.42.0  (homebrew)
    #     perl 5.34.1  (the macOS system perl, with the dependency built for it)
    #
    # The span from 5.10 to 5.32 is inferred from the syntax and has not been
    # tested, and saying so is the point of this comment. Module::Starter's stock
    # 5.008003 is a number nobody ever checked, and a floor copied from a sibling
    # distribution is no better than a guessed one: an earlier draft of this file
    # claimed 5.34 had been run when it had not.
    #
    # Getting 5.34 to run it took installing Object::Proto::Sugar for that perl
    # into a local library. Until that was done only t/01-board.t could run
    # there, because everything else reaches the dependency through the engine,
    # and "we cannot test the old perl" had quietly become "we do not".
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    # One runtime dependency. A second one needs a reason written down.
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Reversi-*' },
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

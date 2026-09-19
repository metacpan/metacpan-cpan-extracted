use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Game::Oware',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Oware.pm',
    ABSTRACT_FROM    => 'lib/Game/Oware.pm',
    LICENSE          => 'artistic_2',
    EXE_FILES        => [ 'bin/oware' ],
    # THE FLOOR, AND WHAT IS EVIDENCE FOR IT.
    #
    # 5.010 is the SYNTACTIC floor and it is a fact rather than a guess: the
    # defined-or operator is used in eight of the eleven modules and in
    # bin/oware, and nothing later than that appears anywhere. Checked rather
    # than assumed, with POD and comments stripped first: no say, no state, no
    # signatures, no postfix dereference, no lexical subs.
    # Object::Proto::Sugar, the one runtime dependency, declares 5.008003, so
    # it does not raise this.
    #
    # THE WHOLE SUITE HAS ACTUALLY BEEN RUN, and passed, on:
    #
    #     perl 5.42.0   (homebrew)
    #     perl 5.34.1   (the macOS system perl)
    #
    # The 5.34 run needed Object::Proto::Sugar built for that perl into a local
    # library, because PERL5LIB in this environment is SET rather than appended
    # and points at the 5.42 tree; without clearing it the old perl loads XS
    # built for the new one and dies with "loadable library and perl binaries
    # are mismatched", which is an environment artifact and not a portability
    # finding.
    #
    # The span from 5.10 to 5.32 is INFERRED FROM THE SYNTAX AND HAS NOT BEEN
    # TESTED, and saying so is the point of this comment. Module::Starter's
    # stock 5.008003 is a number nobody ever checked, and a floor copied from a
    # sibling distribution is no better than a guessed one.
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    # EXACTLY ONE NON-CORE RUNTIME DEPENDENCY. A second one needs a reason
    # written down. Digest::SHA is core and so does not appear here, although
    # Game::Oware::Bot uses it for every tie-break.
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Oware-*' },
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

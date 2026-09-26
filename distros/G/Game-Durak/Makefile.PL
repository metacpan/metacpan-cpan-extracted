use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# The floor is 5.010 and it is measured twice over: Digest::SHA became core at
# 5.9.3 and the deal needs it, and Object::Proto (under Object::Proto::Sugar)
# declares 5.010000 itself, so the distribution cannot honestly claim less.
#
# bin/durak is installed. bin/soak and bin/ladder are in the tarball and are
# NOT installed: they are how the numbers in docs/measured.md were made, and
# a measurement nobody can reproduce is a number in a plan file.

my %WriteMakefileArgs = (
    NAME             => 'Game::Durak',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Durak.pm',
    ABSTRACT_FROM    => 'lib/Game/Durak.pm',
    LICENSE          => q{artistic_2},
    EXE_FILES        => [ q{bin/durak} ],
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        # Digest::SHA is core and is all the deal needs. The house object
        # system is the one non-core prerequisite in the distribution.
        q{Object::Proto::Sugar} => q{0.05},
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Durak-*' },
);

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

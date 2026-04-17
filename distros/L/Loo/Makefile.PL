use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Loo',
    AUTHOR           => 'LNATION <email@lnation.org>',
    VERSION_FROM     => 'lib/Loo.pm',
    ABSTRACT_FROM    => 'lib/Loo.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Loo-*' },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    # XS configuration
    INC    => '-I. -Iinclude',
    OBJECT => '$(O_FILES)',

    # Install headers so dependent XS modules can find them
    PM => {
        'lib/Loo.pm'            => '$(INST_LIB)/Loo.pm',
        'include/loo.h'         => '$(INST_LIB)/Loo/include/loo.h',
        'include/loo_colour.h'  => '$(INST_LIB)/Loo/include/loo_colour.h',
        'include/loo_deparse.h' => '$(INST_LIB)/Loo/include/loo_deparse.h',
        'include/loo_dump.h'    => '$(INST_LIB)/Loo/include/loo_dump.h',
        'include/loo_escape.h'  => '$(INST_LIB)/Loo/include/loo_escape.h',
    },
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

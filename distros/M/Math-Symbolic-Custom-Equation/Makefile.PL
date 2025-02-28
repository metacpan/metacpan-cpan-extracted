use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Math::Symbolic::Custom::Equation',
    AUTHOR           => q{Matt Johnson <mjohnson@cpan.org>},
    VERSION_FROM     => 'lib/Math/Symbolic/Custom/Equation.pm',
    ABSTRACT_FROM    => 'lib/Math/Symbolic/Custom/Equation.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::Simple' => '0',
    },
    PREREQ_PM => {
        'Math::Symbolic'                        =>  '0.613',
        'Math::Symbolic::Custom::Collect'       =>  '0.32',
        'Math::Symbolic::Custom::Factor'        =>  '0.13',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-Symbolic-Custom-Equation-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/mjohnson108/p5-msc-equation.git',
                 web  => 'https://github.com/mjohnson108/p5-msc-equation',
             },
             bugtracker => {
                 web => 'https://github.com/mjohnson108/p5-msc-equation/issues'
             },
             homepage   => 'https://github.com/mjohnson108/',
         },
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

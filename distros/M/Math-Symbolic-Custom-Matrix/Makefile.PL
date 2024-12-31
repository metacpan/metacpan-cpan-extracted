use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Math::Symbolic::Custom::Matrix',
    AUTHOR           => q{Matt Johnson <mjohnson@cpan.org>},
    VERSION_FROM     => 'lib/Math/Symbolic/Custom/Matrix.pm',
    ABSTRACT_FROM    => 'lib/Math/Symbolic/Custom/Matrix.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::Simple' => '0',
    },
    PREREQ_PM => {
        'Math::Symbolic'                            =>  '0.613',
        'Math::Symbolic::Custom::CollectSimplify'   =>  '0.2',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-Symbolic-Custom-Matrix-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/mjohnson108/p5-msc-matrix.git',
                 web  => 'https://github.com/mjohnson108/p5-msc-matrix',
             },
             bugtracker => {
                 web => 'https://github.com/mjohnson108/p5-msc-matrix/issues'
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

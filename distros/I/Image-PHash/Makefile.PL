use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Optional except for cpancover, cpantesters etc.
my $extra_test =
  ( $ENV{EXTENDED_TESTING} || $ENV{AUTOMATED_TESTING} )
  ? 'requires'
  : 'recommends';

my %WriteMakefileArgs = (
    NAME               => 'Image::PHash',
    AUTHOR             => q{Dimitrios Kechagias <dkechag@cpan.org>},
    VERSION_FROM       => 'lib/Image/PHash.pm',
    ABSTRACT_FROM      => 'lib/Image/PHash.pm',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0'               => '0',
        'Test2::Tools::Exception' => '0',
        'Test::More'              => '0',
        'Imager'                  => '0'
    },
    PREREQ_PM => {
        'Math::DCT' => '0'
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        prereqs => {
            test => {
                $extra_test => {
                    'Image::Magick' => '0',
                    'Image::Imlib2' => '0',
                    'GD'            => '0'
                }
            },
            runtime => {
                suggests => {
                    'Image::Imlib2' => '0',
                }
            }
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/dkechag/Image-PHash.git',
                web  => 'https://github.com/dkechag/Image-PHash',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Image-PHash-*' },
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

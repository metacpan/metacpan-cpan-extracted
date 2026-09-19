use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME                => 'Math::Random::Biski64',
    AUTHOR              => 'Scott Baker <https://www.perturb.org>',
    VERSION_FROM        => 'lib/Math/Random/Biski64.pm',
    ABSTRACT_FROM       => 'lib/Math/Random/Biski64.pm',
    MIN_PERL_VERSION    => '5.12.0',
    LICENSE             => 'mit',
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    BUILD_REQUIRES      => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM           => {
        'Carp'      => '0',
    },
    TEST_REQUIRES       => {
        'Test::More' => '0.88',
    },
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                web  => 'https://github.com/bakers/perl-Math-Random-Biski64',
                url  => 'https://github.com/bakers/perl-Math-Random-Biski64.git',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/bakers/perl-Math-Random-Biski64/issues',
            },
            homepage   => 'https://github.com/bakers/perl-Math-Random-Biski64',
        },
        optional_features => {
            'Windows' => {
                description => 'Windows CSPRNG support',
                prereqs => {
                    runtime => {
                        recommends => { 'Win32::API' => '0' },
                    },
                },
            },
        },
    },
    clean => { FILES => 'Math-Random-Biski64-*' },
);

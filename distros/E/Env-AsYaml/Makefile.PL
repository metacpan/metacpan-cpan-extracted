#!/usr/bin/env perl
# Last modified: Thu Aug 14 2025 04:41:36 PM -04:00 [EDT]
use v5.18;
use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Env::AsYaml',
    AUTHOR           => q{Sören Andersen <somian08@gmail.com>},
    VERSION_FROM     => 'lib/Env/AsYaml.pm',
    ABSTRACT         => 'A tool for examination of the environment in which the user is running programs, starting processes or troubleshooting the system.',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => v5.18,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Env'               => '1.05',
        'YAML::Any'         => '1.31',
        'Data::Dump::Color' => '0.251',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Env-AsYaml-*' },
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

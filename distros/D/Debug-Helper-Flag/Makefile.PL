use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Debug::Helper::Flag',
    AUTHOR           => q{Abdul al Hazred <451@gmx.eu>},
    VERSION_FROM     => 'lib/Debug/Helper/Flag.pm',
    ABSTRACT_FROM    => 'lib/Debug/Helper/Flag.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'strict'     => 0,
        'warnings'   => 0,
        'Exporter'   => 0,
        'Test::More' => '0.98',
        'Test::Lib'  => '0.003',
    },
    PREREQ_PM => {
        'strict' => 0,
        'warnings' => 0,
        'feature'  => 0,
        'Exporter' => 0,
        'constant' => 0,
        'Carp'     => 0,
                 },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/AAHAZRED/perl-Debug-Helper-Flag.git',
                web  => 'https://github.com/AAHAZRED/perl-Debug-Helper-Flag',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Debug-Helper-Flag-*' },
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

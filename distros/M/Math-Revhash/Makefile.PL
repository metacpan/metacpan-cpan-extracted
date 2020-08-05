#!/usr/bin/perl
# vim: sw=4 ts=4 et :
use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $NAME = 'Revhash';
my $GIT = 'https://github.com/zhmylove/math-revhash';

my %WriteMakefileArgs = (
    NAME             => "Math::$NAME",
    AUTHOR           => q{Sergei Zhmylev <zhmylove@cpan.org>},
    VERSION_FROM     => "lib/Math/$NAME.pm",
    ABSTRACT_FROM    => "lib/Math/$NAME.pm",
    LICENSE          => "artistic_2",
    MIN_PERL_VERSION => "5.008",
    INSTALLDIRS      => "site",
    META_MERGE       => {
        "meta-spec"  => {version => 2},
        resources    => {
            bugtracker => {web => "$GIT/issues"},
            repository => {
                type => "git",
                url  => "$GIT.git",
                web  => "$GIT",
            },
        },
        x_authority    => "cpan:ZHMYLOVE",
        x_contributors => [], # Feel free to add yourself here ;-)
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {'ExtUtils::MakeMaker' => "6.64",},
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp'          => '0',
        'Exporter'      => '0',
        'Math::BigInt'  => '0',
    },
    test => {TESTS => "t/*.t"},
    dist  => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
        DIST_DEFAULT => 'all tardist',
    },
    clean => { FILES => "Math-$NAME-*" },
    realclean => {FILES => '*~',},

);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} =
        values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} =
        values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };
$WriteMakefileArgs{INSTALLDIRS} = 'perl'
    if "$]" >= 5.006002 && "$]" <= 5.011000;

WriteMakefile(%WriteMakefileArgs);

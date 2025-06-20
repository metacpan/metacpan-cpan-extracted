use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

use File::Spec::Functions;
use autodie;

my $PM_File = catfile(qw(lib Hash Util Exists Tiny.pm));
my $Module_Name = 'Hash::Util::Exists::Tiny';

open(my $h, '<', $PM_File);
my $Version;
foreach my $line (<$h>) {
  if ($line =~ /^our\s+\$VERSION\s+.*?["']([^"']+)["']/) {
    $Version = $1;
    last;
  }
}
close($h);
die("VERSION not found in $PM_File") if !$Version;

my %WriteMakefileArgs = (
    NAME             => $Module_Name,
    AUTHOR           => q{Abdul al Hazred <451@gmx.eu>},
    VERSION_FROM     => 'lib/Hash/Util/Exists/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Hash/Util/Exists/Tiny.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/AAHAZRED/perl-Hash-Util-Exists-Tiny',
                web  => 'https://github.com/AAHAZRED/perl-Hash-Util-Exists-Tiny',
            },
            bugtracker => {
                web => 'https://github.com/AAHAZRED/perl-Hash-Util-Exists-Tiny/issues'
            },

        },
                   provides => { $Module_Name => { file    => $PM_File,
                                                   version => $Version
                                                 },
                    },
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        Exporter => '1.9402',
        strict   => '0',
        warnings => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hash-Util-Exists-Tiny-*' },
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

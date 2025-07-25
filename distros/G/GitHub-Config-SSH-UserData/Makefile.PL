use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Spec::Functions;
use autodie;

my $PM_File = catfile(qw(lib GitHub Config SSH UserData.pm));

my $Version;
open(my $h, '<', $PM_File);
foreach my $line (<$h>) {
  if ($line =~ /\bour\s+\$VERSION\s+.*?["']([^"']+)["']/) {
    $Version = $1;
    last;
  }
}
close($h);
die("VERSION not found in $PM_File") if !$Version;


my %WriteMakefileArgs = (
    NAME             => 'GitHub::Config::SSH::UserData',
    AUTHOR           => q{Klaus Rindfrey <klausrin@cpan.org.eu>},
    VERSION_FROM     => 'lib/GitHub/Config/SSH/UserData.pm',
    ABSTRACT_FROM    => 'lib/GitHub/Config/SSH/UserData.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        'strict'   => 0,
        'warnings' => 0,
        'autodie'  => 0,
        'constant' => 0,
        'Carp'     => 0,
        'File::Spec::Functions' => 0,
        'Exporter' => '1.6',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/klaus-rindfrey/perl-github-config-ssh-userdata.git',
                web  => 'https://github.com/klaus-rindfrey/perl-github-config-ssh-userdata.git',
            },
        },
        bugtracker => {
            web => 'https://github.com/klaus-rindfrey/perl-github-config-ssh-userdata/issues'
        },
        provides => { 'GitHub::Config::SSH::UserData' => {file => $PM_File,
                                                          version => $Version
                                                         },
                    },
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GitHub-Config-SSH-UserData-*' },
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

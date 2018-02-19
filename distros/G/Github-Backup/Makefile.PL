use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Github::Backup',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Github/Backup.pm',
    ABSTRACT_FROM    => 'lib/Github/Backup.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    EXE_FILES        => ['bin/github_backup'],
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/github-backup/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/github-backup.git',
                web => 'https://github.com/stevieb9/github-backup',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Git::Repository' => 1.320,
        'JSON'            => 0,
        'LWP::UserAgent'  => 6.19,
        'Moo'             => 2.003000,
        'Pithub'          => 0.01033,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Github-Backup-*' },
);

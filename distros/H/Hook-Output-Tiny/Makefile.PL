use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Hook::Output::Tiny',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Hook/Output/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Hook/Output/Tiny.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/p5-hook-output-tiny/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/p5-hook-output-tiny.git',
                web => 'https://github.com/stevieb9/p5-hook-output-tiny',
            },
        },
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hook-Output-Tiny-*' },
);

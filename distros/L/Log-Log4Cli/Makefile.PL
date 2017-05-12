use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Log4Cli',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/Log/Log4Cli.pm',
    ABSTRACT_FROM    => 'lib/Log/Log4Cli.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Capture::Tiny'     => 0,
        'Term::ANSIColor'   => 0,
        'Test::More'        => 0,
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/Log-Log4Cli.pm',
        },
    },
    PREREQ_PM => {
        'parent'            => 0,
        'strict'            => 0,
        'warnings'          => 0,
        'Term::ANSIColor'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Log4Cli-* cover_db' },
);

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Hash::Merge::Extra',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/Hash/Merge/Extra.pm',
    ABSTRACT_FROM    => 'lib/Hash/Merge/Extra.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'    => 0,
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/Hash-Merge-Extra.pm',
        },
    },
    PREREQ_PM => {
        'parent'        => 0,
        'strict'        => 0,
        'warnings'      => 0,
        'Hash::Merge'   => 0,
    },
    dist  => { 
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    clean => {
        FILES => 'Hash-Merge-Extra-* cover_db'
    },
);

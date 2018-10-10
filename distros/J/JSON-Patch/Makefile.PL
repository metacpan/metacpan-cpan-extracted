use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'JSON::Patch',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/JSON/Patch.pm',
    ABSTRACT_FROM    => 'lib/JSON/Patch.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'JSON'          => 0,
        'Test::More'    => 0,
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/JSON-Patch.pm',
        },
    },
    PREREQ_PM => {
        'Struct::Diff'                  => 0.96,
        'Struct::Path'                  => 0.82,
        'Struct::Path::JsonPointer'     => 0.04,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'JSON-Patch-* cover_db' },
);


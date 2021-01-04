use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME             => 'List::Breakdown',
    AUTHOR           => 'Tom Ryder <tom@sanctum.geek.nz>',
    VERSION_FROM     => 'lib/List/Breakdown.pm',
    ABSTRACT_FROM    => 'lib/List/Breakdown.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp'     => '0',
        'Exporter' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'List::Breakdown' => {
                version => '0.23',
                file => 'lib/List/Breakdown.pm',
            },
        },
        resources => {
            homepage => 'https://sanctum.geek.nz/cgit/List-Breakdown.git/',
            repository => {
                type => 'git',
                url => 'https://sanctum.geek.nz/code/List-Breakdown.git/',
                web => 'https://sanctum.geek.nz/cgit/List-Breakdown.git/',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'List-Breakdown-*' },
);

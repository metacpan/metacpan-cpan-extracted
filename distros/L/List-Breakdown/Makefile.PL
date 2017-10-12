use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
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
        provides => {
            'List::Breakdown' => {
                version => '0.20',
                file => 'lib/List/Breakdown.pm',
            },
        },
        resources => {
            homepage => 'https://sanctum.geek.nz/cgit/List-Breakdown.git/',
            repository => 'https://sanctum.geek.nz/code/List-Breakdown.git/',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'List-Breakdown-*' },
);

use strict;
use warnings;
use ExtUtils::MakeMaker 7;

WriteMakefile(
    NAME                => 'Keyword::Declare',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Keyword/Declare.pm',
    ABSTRACT_FROM       => 'lib/Keyword/Declare.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.012,
    TEST_REQUIRES => {
        'Test::More'      => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 7,
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 7,
    },
    PREREQ_PM => {
        'PPR'                  => '0.000015',
        'List::Util'           => 1.45,
        'Keyword::Simple'      => 0,
        'B::Hooks::EndOfScope' => 0,
    },
    META_MERGE   => {
        no_index => {
            directory => [qw/demo dlib/],
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Keyword-Declare-*' },
);

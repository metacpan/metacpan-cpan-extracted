use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Locale::Maketext::Lexicon::Getcontext',
    LICENSE             => 'mit',
    AUTHOR              => 'Sebastien Aperghis-Tramoni (saper@cpan.org)',
    VERSION_FROM        => 'lib/Locale/Maketext/Lexicon/Getcontext.pm',
    ABSTRACT_FROM       => 'lib/Locale/Maketext/Lexicon/Getcontext.pm',
    META_MERGE          => {
        resources       => {
            repository  => 'https://github.com/maddingue/Locale-Maketext-Lexicon-Getcontext',
        },
    },
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'                      => 0,
        'Locale::Maketext::Lexicon' => 0,
        'Locale::Maketext::Lexicon::Gettext' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'                => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

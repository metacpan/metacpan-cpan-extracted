use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Math::PhaseOnlyCorrelation',
    AUTHOR              => 'moznion <moznion@gmail.com>',
    VERSION_FROM        => 'lib/Math/PhaseOnlyCorrelation.pm',
    ABSTRACT_FROM       => 'lib/Math/PhaseOnlyCorrelation.pm',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0.98,
        'Test::Most' => 0.31,
        'ExtUtils::MakeMaker' => 6.62,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.62,
    },
    PREREQ_PM => {
        'Math::FFT' => 1.28,
        'List::MoreUtils' => 0.33,
    },
    META_MERGE => {
        resources => {
            license => 'http://dev.perl.org/licenses/',
            repository => 'git://github.com/moznion/Math--PhaseOnlyCorrelation.git',
        },
    },
    LICENSE             => 'perl',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Math-PhaseOnlyCorrelation-*' },
);

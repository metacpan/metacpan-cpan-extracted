use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FTN::SRIF',
    AUTHOR              => 'Robert James Clay <jame@rocasa.us>',
    VERSION_FROM        => 'lib/FTN/SRIF.pm',
    ABSTRACT_FROM       => 'lib/FTN/SRIF.pm',
    LICENSE        	=> 'perl',
    EXE_FILES           => [ qw( bin/ftn-srif ) ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Config::Tiny' => 0,
        'FTN::Log' => 0.02,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FTN-SRIF-*' },
);

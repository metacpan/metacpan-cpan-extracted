use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FTN::JAM',
    AUTHOR              => 'Robert James Clay <jame@rocasa.us>',
    VERSION_FROM        => 'lib/FTN/JAM.pm',
    ABSTRACT_FROM       => 'lib/FTN/JAM.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Readonly'      => 0,
        'Time::Local'   => 0,
        'Time::Zone'    => 0,
        'Test::More'    => 0,
        'Test::Pod'     => 1.22,
        'Test::Pod::Coverage'   => 1.08,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', ZIPFLAGS => '-or9', },
    clean               => { FILES => 'FTN-JAM-* t/TEST*.j*' },
);

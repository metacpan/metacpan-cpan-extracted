use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Device::Delcom::VSI',
    AUTHOR              => 'G. Wade Johnson <wade@anomaly.org>',
    VERSION_FROM        => 'lib/Device/Delcom/VSI.pm',
    ABSTRACT_FROM       => 'lib/Device/Delcom/VSI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Device::USB' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-Delcom-VSI-*' },
);

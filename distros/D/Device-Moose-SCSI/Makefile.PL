use 5.006;
use strict;
use warnings FATAL => "all";
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME                => "Device::Moose::SCSI",
    AUTHOR              => q{potatogim <potatogim@potatogim.net>},
    VERSION_FROM        => "lib/Device/Moose/SCSI.pm",
    ABSTRACT_FROM       => "lib/Device/Moose/SCSI.pm",
    LICENSE             => "perl",
    PL_FILES            => {},
    MIN_PERL_VERSION    => 5.006,
    CONFIGURE_REQUIRES  => {
        "ExtUtils::MakeMaker" => 0,
    },
    BUILD_REQUIRES => {
        "Test::More" => 0,
    },
    PREREQ_PM => {
        "Moose"            => 0,
        "namespace::clean" => 0,
        "Carp"             => 0,
        "IO::File"         => 0,
    },
    dist => {
        COMPRESS => "gzip -9f",
        SUFFIX   => "gz",
    },
    clean => {
        FILES => "Device-Moose-SCSI-*"
    },
);

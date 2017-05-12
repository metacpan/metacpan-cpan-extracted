use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Device::Video::PWC',
    VERSION_FROM  => 'PWC.pm',
    PREREQ_PM => {
        'XSLoader'     => 0,
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'Device-Video-PWC-*' },
);

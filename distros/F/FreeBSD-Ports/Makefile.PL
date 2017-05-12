use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FreeBSD::Ports',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/FreeBSD/Ports.pm',
    ABSTRACT_FROM       => 'lib/FreeBSD/Ports.pm',
    PL_FILES            => {},
    INST_SCRIPT => 'bin',
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FreeBSD-Ports-*' },
);

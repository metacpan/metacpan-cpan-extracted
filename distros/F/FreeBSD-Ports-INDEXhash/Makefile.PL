use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FreeBSD::Ports::INDEXhash',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/FreeBSD/Ports/INDEXhash.pm',
    ABSTRACT_FROM       => 'lib/FreeBSD/Ports/INDEXhash.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FreeBSD-Ports-INDEXhash-*' },
);

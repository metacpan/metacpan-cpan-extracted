use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FreeBSD::Pkgs::FindUpdates',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/FreeBSD/Pkgs/FindUpdates.pm',
    ABSTRACT_FROM       => 'lib/FreeBSD/Pkgs/FindUpdates.pm',
    PL_FILES            => {},
    INST_SCRIPT => 'bin',
    PREREQ_PM => {
        'Test::More' => 0,
		'Sort::Versions' => 0,
		'FreeBSD::Ports::INDEXhash' => 0,
        'FreeBSD::Pkgs' => 0,
		'Error::Helper'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FreeBSD-Pkgs-FindUpdates-*' },
);

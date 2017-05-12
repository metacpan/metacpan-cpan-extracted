use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FreeBSD::Pkgs',
    AUTHOR              => 'Zane C. Bowers-Hadley <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/FreeBSD/Pkgs.pm',
    ABSTRACT_FROM       => 'lib/FreeBSD/Pkgs.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Error::Helper'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FreeBSD-Pkgs-*' },
	);

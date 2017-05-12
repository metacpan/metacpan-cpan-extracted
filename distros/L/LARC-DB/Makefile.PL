use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LARC::DB',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/LARC/DB.pm',
    ABSTRACT_FROM       => 'lib/LARC/DB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	    'DBI' => 0,
	    'File::Path' => 0,
        'DBD::SQLite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LARC-DB-*' },
);

require 5.008;
use ExtUtils::MakeMaker;

print <<'EOMSG';

***
*** The test suite for this package requires that the
*** wdb2merc utility has been run against the WDB
*** datasets to generate the Mercator projected
*** binary data files, and the WDB_BIN environment
*** variable has been set to the directory path
*** of the binary data.
***
EOMSG

WriteMakefile(
    NAME			=> 'GD::Map::Mercator',
    VERSION_FROM	=> 'lib/GD/Map/Mercator.pm',
    PREREQ_PM		=> {
    	'GD'			=> '2.30',
    	'Geo::Mercator' => '1.01'
    },
    'dist'			=> { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
    EXE_FILES       => [ 'bin/wdb2merc.pl' ],
	AUTHOR			=> 'Dean Arnold <darnols@presicient.com>',
    ABSTRACT 		=> 'Create Mercator projected map images using GD',
);

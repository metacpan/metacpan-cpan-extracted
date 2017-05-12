use ExtUtils::MakeMaker;

use strict ;

WriteMakefile(
    'NAME'          => 'FileMetadata',
    'VERSION'  => '0.1',
    'PREREQ_PM'     => {
			'XML::Simple'  => 0,
			'HTML::Parser'  => 0,
			'POSIX'  => 0,
			'DBI'  => 0
		       },
    clean => {FILES => "temp.*"}
);



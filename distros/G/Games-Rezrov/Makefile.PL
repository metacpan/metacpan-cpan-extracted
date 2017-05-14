use ExtUtils::MakeMaker;
use 5.005;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'DISTNAME'  => 'Games-Rezrov',
	      'NAME'	=> 'Games::Rezrov::ZInterpreter',
	      'VERSION_FROM' => 'rezrov',
	      'EXE_FILES' => [ 'rezrov' ],
#	      'PREREQ_PM' => { '5.005' => 0 },
# how to require a particular perl version level...?
	      'dist' => {
			 "ZIPFLAGS" => "-r9",
			 'COMPRESS' => 'gzip -f9',
			},
);

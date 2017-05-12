use strict ;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'File::Slurp',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'Uri Guttman <uri@stemsystems.com>',
	'VERSION_FROM'	=> 'lib/File/Slurp.pm',
	'ABSTRACT_FROM' => 'lib/File/Slurp.pm',
	'META_MERGE'    => {
		requires	=> {
			perl	=> 5.004,
		},
	},
	'PREREQ_PM'	=> {
		'Carp'      => 0,
		'Exporter'  => 0,
		'Fcntl'     => 0,
		'POSIX'     => 0,
	},
);

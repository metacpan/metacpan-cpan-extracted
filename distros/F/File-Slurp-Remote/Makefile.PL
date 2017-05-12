
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/Tie/Function/Examples.pm',
	'NAME' => 'File-Slurp-Remote',
	'ABSTRACT' => 'Easy read/write of remote files',
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'PREREQ_PM'	=> {
		'File::Temp'		=> 0,
		'Sys::Hostname::FQDN'	=> 0,
		'File::Slurp'		=> 0,
		'File::Temp'		=> 0,
		'Tie::Hash'		=> 0,
	},
);


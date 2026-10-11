
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/File/Slurp/Remote.pm',
	'NAME' => 'File::Slurp::Remote',
	'ABSTRACT' => 'Easy read/write of remote files',
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>',
	clean		=> { FILES => 'File-Slurp-Remote-*' },
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	PREREQ_PM => {
		'File::Slurp' => 0,
		'File::Temp'	=> 0,
		'Sys::Hostname::FQDN'	=> 0,
		'File::Slurp'		=> 0,
		'File::Temp'		=> 0,
		'Tie::Hash'		=> 0,
	},
);


use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/File/BasicFlock.pm',
	'NAME'	  => 'File::BasicFlock',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Thin interface to flock()',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	);


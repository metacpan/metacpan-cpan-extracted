
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/List/EvenMoreUtils.pm',
	'NAME' => 'List-EvenMore',
	($] >= 5.005 ?
	('ABSTRACT' => 'Even more List utilities',
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>') : ()),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'PREREQ_PM' => {
		'String::CRC'		=> 0,
	},
);


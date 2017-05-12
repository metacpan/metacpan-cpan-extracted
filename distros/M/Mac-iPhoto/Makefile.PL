use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Mac::iPhoto',
	'VERSION_FROM'		=> 'iPhoto.pm',
	'PREREQ_PM'	=> {
    		'Mac::PropertyList'   => 0.10,
	},
	'clean'	=> {
		'FILES'	=> 'Mac-iPhoto-*'
	},
);

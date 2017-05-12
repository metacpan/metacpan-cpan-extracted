use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Mac::Apps::Launch',
	'VERSION_FROM'		=> 'Launch.pm',
	'PREREQ_PM'	=> {
    		'Mac::Processes'   => 1.04,
    		'Test::More'       => 0,
	},
	'clean'	=> {
		'FILES'	=> 'Mac-Apps-Launch-*'
	},
	'NO_META'		=> 1,
);

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Mac::AppleEvents::Simple',
	'VERSION_FROM'		=> 'Simple.pm',
	'PREREQ_PM'	=> {
    		'Mac::Apps::Launch'  => 1.81,
    		'Mac::AppleEvents'   => 1.30,
    		'Mac::Processes'     => 1.04,
    		'Mac::Errors'        => 0.91,
    		'Test::More'         => 0,
    		'Time::Epoch'        => 0.02,
    		'URI'                => 0,
	},
	'clean'	=> {
		'FILES'	=> 'Mac-AppleEvents-Simple-*'
	},
	'NO_META'		=> 1,
);

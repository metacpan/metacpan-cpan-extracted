use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Devel::FindGlobals',
	'VERSION_FROM'		=> 'FindGlobals.pm',
	'PREREQ_PM'		=> {
		'Test::More'	=> 0,
		'Devel::Size'	=> 0,
	},
	'clean'			=> {
		'FILES'	=> 'Devel-FindGlobals-*'
	},
	'NO_META'		=> 1,
);

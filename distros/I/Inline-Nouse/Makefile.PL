use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Inline::Nouse',
	'VERSION_FROM'	=> 'lib/Inline/Nouse.pm',
	'PREREQ_PM'	=> {
		'Inline'		=> 0.44,
		'Inline::Interp'	=> 0.06,
		'Language::Nouse'	=> 0.03,
		'Test::More'		=> 0,
	},
);

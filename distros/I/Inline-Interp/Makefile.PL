use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Inline::Interp',
    'VERSION_FROM'	=> 'lib/Inline/Interp.pm',
    'PREREQ_PM'		=> {
		Inline		=> 0.50,
		Test::More	=> 0,
	},
);

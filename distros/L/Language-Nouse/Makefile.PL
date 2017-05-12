use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Language::Nouse',
	'VERSION_FROM'	=> 'Nouse.pm',
	'PREREQ_PM'	=> {
				Test::Simple => 0
			},
);

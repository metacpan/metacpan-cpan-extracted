use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Language::Homespring',
    'VERSION_FROM'	=> 'Homespring.pm',
    'PREREQ_PM'		=> {
				Test::Simple => 0,
			},
);

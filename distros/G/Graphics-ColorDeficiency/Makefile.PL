use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Graphics::ColorDeficiency',
    'VERSION_FROM'	=> 'ColorDeficiency.pm',
    'PREREQ_PM'		=> {
					Graphics::ColorObject	=> 0,
					Test::Simple		=> 0,
				},
);

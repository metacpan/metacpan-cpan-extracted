use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Image::Caa',
	'VERSION_FROM'	=> 'lib/Image/Caa.pm',
	'PREREQ_PM'	=> {
				'Test::More'	=> 0,
				'Curses'	=> 0,
			},
);

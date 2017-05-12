use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Games::OpenGL::Font::2D',
    'VERSION_FROM'	=> 'lib/Games/OpenGL/Font/2D.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			SDL => 'v2.1.3',
			},
    'LIBS'		=> [ ],	# e.g., '-lm'
    'DEFINE'		=> '',	# e.g., '-DHAVE_SOMETHING'
    'INC'		=> '',	# e.g., '-I/usr/include/other'
);

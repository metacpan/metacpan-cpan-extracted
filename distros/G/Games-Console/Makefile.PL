use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Games::Console',
    'VERSION_FROM'	=> 'lib/Games/Console.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			SDL => 'v1.20.3', # http://bloodgate.com/perl/sdl/
			Games::OpenGL::Font::2D => '0.05',
			}, # e.g., Module::Name => 1.1
    'LIBS'		=> [ ], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Eesh',
    'VERSION_FROM' => 'Eesh.pm', # finds $VERSION
    'LIBS'	=> ['-L/usr/X11R6/lib -lX11'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/usr/include/X11',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => '$(BASEEXT)$(OBJ_EXT)',
);


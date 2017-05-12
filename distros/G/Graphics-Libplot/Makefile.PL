use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Graphics::Libplot',
    'VERSION_FROM' => 'Libplot.pm', # finds $VERSION
    #'LIBS'	=> ['-lplot -L/usr/X11R6/lib -lXaw -lXmu -lXt -lSM -lICE -lXext -lX11 -lm'], 
    'LIBS'	=> '-lplot',
#    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
#    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);

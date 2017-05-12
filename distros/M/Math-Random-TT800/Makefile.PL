use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Math::Random::TT800',
    'DISTNAME' => 'Math-Random-TT800',
    'VERSION_FROM' => 'TT800.pm', # finds $VERSION
    'OBJECT'	=> 'TT800.o tt800_core.o',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);

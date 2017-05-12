use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'	=> 'Philippe CHANE-YOU-KAYE philippe.cyk@wanadoo.fr',
    'ABSTRACT'	=> 'Interface to C-ISAM files',
    'NAME'	=> 'Isam',
    'VERSION_FROM' => 'Isam.pm', # finds $VERSION
    'LIBS'	=> ['-lisam'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PMLIBDIRS'	=> [ 'lib', ${BASEEXT}, 'eg' ],
);

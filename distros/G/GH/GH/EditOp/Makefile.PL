use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GH::EditOp',
    'VERSION_FROM'	=> 'EditOp.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'CCFLAGS'           => '-g',
    'INC'		=> '-I..', # e.g., '-I/usr/include/other'
    'OBJECT'		=> 'EditOp.o _editop.o',
);

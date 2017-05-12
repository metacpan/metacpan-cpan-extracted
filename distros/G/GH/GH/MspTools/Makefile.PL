use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GH::MspTools',
    'VERSION_FROM'	=> 'MspTools.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I. -I.. ', # e.g., '-I/usr/include/other'
    'CCFLAGS'           => '-g',
    'OBJECT'		=> 'MspTools.o msp_tools.o msp_helpers.o',
);

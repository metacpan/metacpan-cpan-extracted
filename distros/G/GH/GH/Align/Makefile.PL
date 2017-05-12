use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME' => 'GH::Align',
	      'VERSION_FROM' => 'Align.pm', # finds $VERSION
	      'PREREQ_PM' => {}, # e.g., Module::Name => 1.1
	      'LIBS' => [''], # e.g., '-lm'
	      'DEFINE' => '', # e.g., '-DHAVE_SOMETHING'
	      'INC' => '-I..', # e.g., '-I/usr/include/other'
    	      'CCFLAGS'           => '-g',
	      'OBJECT' => 'Align.o align_helpers.o align_tools.o align_bounded_hirsch.o align_context.o',
	     );

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%opts = (
	      'NAME'		=> 'Getopt::Long::GUI',
	      'VERSION_FROM'	=> 'GUI.pm', # finds $VERSION
	);

WriteMakefile(%opts);

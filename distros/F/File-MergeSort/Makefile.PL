use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile('NAME'         => 'File::MergeSort',
	      'VERSION_FROM' => 'lib/File/MergeSort.pm', # finds $VERSION
	      'LICENSE'      => 'perl',
	      'PREREQ_PM'    => { 'IO::File'   => '0',
				  'Test::More' => '0',
				},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT_FROM => 'lib/File/MergeSort.pm', # retrieve abstract from module
		 AUTHOR        => 'Barrie Bremner') : ()),
	     );

use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'IO::StructuredOutput',
    'VERSION_FROM'	=> 'StructuredOutput.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	            		'Text::CSV_XS' => 0,
	            		'IO::Scalar' => 0,
	            		'Archive::Zip' => 0,
	            		'Spreadsheet::WriteExcel' => 0,
	            	    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'StructuredOutput.pm', # retrieve abstract from module
       AUTHOR     => 'Josh Miller <jmiller@public-dns.org>') : ()),
);

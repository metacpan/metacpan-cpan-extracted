use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::PrettyPrinter',
    'VERSION_FROM' => 'PrettyPrinter.pm', # finds $VERSION
    'PREREQ_PM' => {'HTML::Element' => 3.02,
		    'HTML::Tagset'  => 3.01,
		   },		    
    'dist'           => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 'MD5::Reverse',
    'VERSION_FROM'	=> 'Reverse.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
    					 'Digest::MD5' => 0.1,
    					  }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
      	ABSTRACT_FROM 	=> 'Reverse.pm', # retrieve abstract from module
       	AUTHOR     		=> 'Maciej Ceglowski <maciej@ceglowski.com>') : ()),

);

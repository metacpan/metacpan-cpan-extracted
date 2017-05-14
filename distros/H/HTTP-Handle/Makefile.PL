use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::Handle',
    #'VERSION_FROM'	=> 'Handle.pm',
	 'VERSION'        => '0.2',
    'PREREQ_PM'		=> { 
								 URI => 0 
								},
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Handle.pm', 
       AUTHOR     => 'Jordan Sissel <psionic@csh.rit.edu>') : ()),
);

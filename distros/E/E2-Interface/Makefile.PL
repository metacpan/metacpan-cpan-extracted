use 5.006;
use ExtUtils::MakeMaker;
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'E2::Interface',
    'VERSION_FROM'	=> 'Interface.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    				'LWP' 			=> 0,
    				'XML::Twig'		=> 0,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Interface.pm', # retrieve abstract from module
       AUTHOR     => 'Jose M. Weeks <jose@joseweeks.com>') : ()),
);

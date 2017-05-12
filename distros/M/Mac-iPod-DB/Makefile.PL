# $Id: Makefile.PL,v 1.1.1.1 2003/07/30 01:55:25 sps Exp $
require 5.005_03;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mac::iPod::DB',
    'VERSION_FROM'	=> 'DB.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM => 'DB.pm', # retrieve abstract from module
      AUTHOR     => 'Sean Scanlon <sps AT bluedot.net>') : ()),
);

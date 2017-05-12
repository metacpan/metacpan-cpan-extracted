###########################################################################
#
# $Id: Makefile.PL,v 1.2 2005/01/18 20:49:21 pkaluski Exp $
# $Name: Stable_0_16 $
#
# Makefile generation
#
# $Log: Makefile.PL,v $
# Revision 1.2  2005/01/18 20:49:21  pkaluski
# Converted files from DOS to Unix format
#
# Revision 1.1  2004/12/10 22:26:56  pkaluski
# Making module CPAN and ppm compatible
#
#
###########################################################################
use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'LRpt',
    'VERSION_FROM'	=> 'LRpt.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'LRpt.pm', # retrieve abstract from module
       AUTHOR     => 'Piotr Kaluski <pkaluski@piotrkaluski.com>') : ()),
);

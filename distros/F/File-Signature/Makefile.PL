# $Id: Makefile.PL,v 1.1 2003/06/10 22:01:30 jeremy Exp $
use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::Signature',
    'VERSION_FROM'	=> 'Signature.pm', # finds $VERSION
    'PREREQ_PM'		=> {Digest::MD5 => 2.12 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Signature.pm', # retrieve abstract from module
       AUTHOR     => 'Jeremy Madea <jdm@pobox.com>') : ()),
);

# $Log: Makefile.PL,v $
# Revision 1.1  2003/06/10 22:01:30  jeremy
# Initial revision
#

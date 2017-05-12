#
# $Id: Makefile.PL,v 1.2 2004/06/19 09:39:29 cosimo Exp $
#
#use 5.005;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::Proxy::BodyFilter::Adnix',
    'VERSION_FROM'	=> 'Adnix.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'HTTP::Proxy' => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Adnix.pm', # retrieve abstract from module
       AUTHOR     => 'Cosimo Streppone <cosimo@cpan.org>') : ()),
);

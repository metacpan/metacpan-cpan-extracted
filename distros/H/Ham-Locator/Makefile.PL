# Makefile.PL
# $Id: Makefile.PL 17 2009-12-15 01:36:48Z andys $

use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ham::Locator',
    VERSION_FROM      => 'lib/Ham/Locator.pm', # finds $VERSION
	PREREQ_PM		  => {'Class::Accessor' => 0.34},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ham/Locator.pm', # retrieve abstract from module
       AUTHOR         => 'Andy Smith <andy.smith@nsnw.co.uk>') : ()),
);

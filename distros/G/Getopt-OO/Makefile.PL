# $Log: Makefile.PL,v $
# Revision 1.3  2005/01/23 22:17:35  sjs
# Use perl 5.004.
#
# Revision 1.2  2005/01/17 06:52:36  sjs
#
# Makefile: move required version to 5.005.
# Bumped version to 2.
#
# Revision 1.1.1.1  2005/01/10 05:23:52  sjs
# Import of Getopt::OO
#
use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Getopt::OO',
    VERSION_FROM      => 'lib/Getopt/OO.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Getopt/OO.pm', # retrieve abstract from module
       AUTHOR         => 'sjsmith <sjs@chaos-tools.com>') : ()),
);

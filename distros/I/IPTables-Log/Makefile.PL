# Makefile.PL
# $Id: Makefile.PL 20 2010-12-17 21:05:28Z andys $

use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPTables::Log',
    VERSION_FROM      => 'lib/IPTables/Log.pm', # finds $VERSION
    PREREQ_PM         => {'Data::GUID' => 0.045, 'NetAddr::IP' => 4.027, 'Class::Accessor' => 0.34}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPTables/Log.pm', # retrieve abstract from module
       AUTHOR         => 'Andy Smith <ams@meh.org.uk>') : ()),
);

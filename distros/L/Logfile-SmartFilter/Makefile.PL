use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Logfile::SmartFilter',
    VERSION_FROM      => 'lib/Logfile/SmartFilter.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Logfile/SmartFilter.pm', # retrieve abstract from module
       AUTHOR         => 'Functional user for logs transfers <cce@net.bms.com>') : ()),
);

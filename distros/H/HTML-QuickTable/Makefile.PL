use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::QuickTable',
    VERSION_FROM      => 'lib/HTML/QuickTable.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/QuickTable.pm', # retrieve abstract from module
       AUTHOR         => 'Nathan Wiger <nwiger@sun.com>') : ()),
);

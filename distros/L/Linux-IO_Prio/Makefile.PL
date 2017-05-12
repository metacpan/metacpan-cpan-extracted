use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Linux::IO_Prio',
    VERSION_FROM      => 'lib/Linux/IO_Prio.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Linux/IO_Prio.pm', # retrieve abstract from module
       LICENSE        => 'perl',
       AUTHOR         => 'Mark Hindley <mark@hindley.org.uk>') : ()),
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Hash::Search',
    VERSION_FROM      => 'lib/Hash/Search.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Hash/Search.pm', # retrieve abstract from module
       AUTHOR         => 'Steve Brokenshire <sbrokenshire@xestia.co.uk>') : ()),
);

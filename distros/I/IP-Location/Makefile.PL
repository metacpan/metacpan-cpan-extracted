use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IP::Location',
    VERSION_FROM      => 'lib/IP/Location.pm', # finds $VERSION
    PREREQ_PM         => {
                            Encode          => 2.12,
                            Encode::CNMap   => 0.32,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IP/Location.pm', # retrieve abstract from module
       AUTHOR         => 'michael.wang <michael@localdomain>') : ()),
);

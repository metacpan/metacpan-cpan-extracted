use 5.001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IP::Anonymous',
    VERSION_FROM      => 'lib/IP/Anonymous.pm', # finds $VERSION
    PREREQ_PM         => { Crypt::Rijndael => 0.04 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IP/Anonymous.pm', # retrieve abstract from module
       AUTHOR         => 'John Kristoff <jtk@northwestern.edu>') : ()),
);

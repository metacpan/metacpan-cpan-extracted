use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Getopt::ApacheCommonsCLI',
    LICENSE           => 'perl_5',
    VERSION_FROM      => 'lib/Getopt/ApacheCommonsCLI.pm', # finds $VERSION
    PREREQ_PM         => { Getopt::Long => 2.35, constant => 0, }, # e.g., Module::Name => 1.1
    TEST_REQUIRES     => { Test::More => 0, Data::Dumper => 0, },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Getopt/ApacheCommonsCLI.pm', # retrieve abstract from module
       AUTHOR         => 'James Briggs <james.briggs@yahoo.com>') : ()),
);


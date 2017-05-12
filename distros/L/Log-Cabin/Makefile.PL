use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Log::Cabin',
    VERSION_FROM      => 'lib/Log/Cabin.pm', # finds $VERSION
    PREREQ_PM         => { }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Log/Cabin.pm', # retrieve abstract from module
       AUTHOR         => 'Joshua Orvis <jorvis@tigr.org>') : ()),
);

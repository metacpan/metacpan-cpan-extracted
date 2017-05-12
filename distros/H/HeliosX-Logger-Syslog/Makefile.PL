use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HeliosX::Logger::Syslog',
    VERSION_FROM      => 'lib/HeliosX/Logger/Syslog.pm', # finds $VERSION
    LICENSE           => 'artistic_2',    
    PREREQ_PM         => {
    	                   Helios       => 2.30,
    	                   Sys::Syslog  => 0.23
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HeliosX/Logger/Syslog.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew Johnson <lajandy at cpan dotorg>') : ()),
);

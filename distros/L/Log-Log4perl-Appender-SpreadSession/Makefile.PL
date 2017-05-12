use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Log::Log4perl::Appender::SpreadSession',
    VERSION_FROM      => 'lib/Log/Log4perl/Appender/SpreadSession.pm', # finds $VERSION
    PREREQ_PM         => { 
                          Spread::Session => 0.4,
                          Log::Log4perl => 1.10,
                      }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Log/Log4perl/Appender/SpreadSession.pm', # retrieve abstract from module
       AUTHOR         => 'Trevor J. Little <bundacia@tjlittle.com>') : ()),
);

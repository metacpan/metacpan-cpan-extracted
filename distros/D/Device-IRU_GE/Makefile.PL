use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::IRU_GE',
    VERSION_FROM      => 'lib/Device/IRU_GE.pm', # finds $VERSION
    PREREQ_PM         =>  { Device::SerialPort=>1.04   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/IRU_GE.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@localdomain>') : ()),
);

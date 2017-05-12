use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::USB::PanicButton',
    VERSION_FROM      => 'lib/Device/USB/PanicButton.pm', # finds $VERSION
    PREREQ_PM         => { Device::USB }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/USB/PanicButton.pm', # retrieve abstract from module
       AUTHOR         => 'Benjamin Kendinibilir <cpan@kendinibilir.de>') : ()),
);

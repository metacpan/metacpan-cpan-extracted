use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Modem::SMSModem',
    VERSION_FROM      => 'lib/Device/Modem/SMSModem.pm', # finds $VERSION
    PREREQ_PM         => {'Device::Modem' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Modem/SMSModem.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry Cheban <dmitriii@gmail.com>') : ()),
);

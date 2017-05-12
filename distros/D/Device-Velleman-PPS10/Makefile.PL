use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Velleman::PPS10',
    VERSION_FROM      => 'lib/Device/Velleman/PPS10.pm', # finds $VERSION
    PREREQ_PM         => {
	'Device::SerialPort'	=> '1.04',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM  => 'lib/Device/Velleman/PPS10.pm', # retrieve abstract from module
      AUTHOR         => 'Narbey Derbekyan <narbey@localdomain>') : ()),
);

use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::BCM2835::NES',
    VERSION_FROM      => 'lib/Device/BCM2835/NES.pm', # finds $VERSION
    PREREQ_PM         => {
		'Device::BCM2835' => 1.3
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/BCM2835/NES.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Kloberdanz <klobyone@gmail.com>') : ()),
);

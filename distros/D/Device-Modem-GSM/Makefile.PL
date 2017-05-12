use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Modem::GSM',
    VERSION_FROM      => 'lib/Device/Modem/GSM.pm', # finds $VERSION
    PREREQ_PM         => {
		'Device::Modem' => '1.47'
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Modem/GSM.pm', # retrieve abstract from module
       AUTHOR         => 'Stephane KATTOOR <stephane.kattoor@cpan.org>') : ()),
);

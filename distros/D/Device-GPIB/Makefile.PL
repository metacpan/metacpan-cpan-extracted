use 5.034000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::GPIB',
    VERSION_FROM      => 'lib/Device/GPIB.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Device/GPIB.pm', # retrieve abstract from module
    AUTHOR            => 'Mike McCauley <mikem@>',
    LICENSE           => 'perl',
);

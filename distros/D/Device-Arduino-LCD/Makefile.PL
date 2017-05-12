use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Arduino::LCD',
    VERSION_FROM      => 'lib/Device/Arduino/LCD.pm', # finds $VERSION
    PREREQ_PM         => { Device::SerialPort => 0,
			   Class::MethodMaker => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Arduino/LCD.pm', # retrieve abstract from module
       AUTHOR         => 'kevin montuori <montuori@gmail.com>') : ()),
);

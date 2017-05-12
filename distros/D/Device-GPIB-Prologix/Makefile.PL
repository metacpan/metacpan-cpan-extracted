use 5.018001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @exe_files = ('bin/tekscreendump.pl');

WriteMakefile(
    NAME              => 'Device::GPIB::Prologix',
    VERSION_FROM      => 'lib/Device/GPIB/Prologix.pm', # finds $VERSION
    PREREQ_PM         => {'Device::SerialPort' => 0 },
    EXE_FILES         => \@exe_files,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/GPIB/Prologix.pm', # retrieve abstract from module
       AUTHOR         => 'Mike McCauley <mikem@airspayce.com>') : ()),
);

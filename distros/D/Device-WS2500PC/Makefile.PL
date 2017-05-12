use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::WS2500PC',
    VERSION_FROM      => 'lib/Device/WS2500PC.pm', 
    PREREQ_PM         => {'Device::SerialPort'=>0, 'Time::HiRes'=>0, 'Time::Local'=>0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/WS2500PC.pm', # retrieve abstract from module
       AUTHOR         => 'Magnus Schmidt <ws2500@27b-6.de>') : ()),
    ABSTRACT_FROM     => 'lib/Device/WS2500PC.pod'
);

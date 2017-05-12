use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::XBee::API',
    VERSION_FROM      => 'lib/Device/XBee/API.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/XBee/API.pm', # retrieve abstract from module
       AUTHOR         => 'jeagle@cpan.org') : ()),
);

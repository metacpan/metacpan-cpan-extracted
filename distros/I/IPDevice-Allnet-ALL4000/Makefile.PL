use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPDevice::Allnet::ALL4000',
    VERSION_FROM      => 'lib/IPDevice/Allnet/ALL4000.pm', # finds $VERSION
    PREREQ_PM         => {  LWP::UserAgent => '0',
							XML::Parser => '0',
						},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPDevice/Allnet/ALL4000.pm', # retrieve abstract from module
       AUTHOR         => 'Robin Clarke <rcl@robinclarke.net>') : ()),
);

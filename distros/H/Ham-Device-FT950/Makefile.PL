use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @exefiles = 'bin/pRigctl.plx';
WriteMakefile(
    NAME              => 'Ham::Device::FT950',
    VERSION_FROM      => 'lib/Ham/Device/FT950.pm', # finds $VERSION
    EXE_FILES	      => \@exefiles,
    PREREQ_PM         => { Device::SerialPort => 0.22 } , # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ham/Device/FT950.pm', # retrieve abstract from module
       AUTHOR         => 'Tim Gimmel <ky4j@arrl.net>') : ()),
);

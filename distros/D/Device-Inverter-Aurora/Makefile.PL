use 5.008008;
use ExtUtils::MakeMaker 6.55_03;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Inverter::Aurora',
    VERSION_FROM      => 'lib/Device/Inverter/Aurora.pm', # finds $VERSION
    PREREQ_PM         => {
        ($^O eq "MSWin32" || $^O eq "cygwin"
            ? (Win32::SerialPort => 0.11)
            : (Device::SerialPort => 1.002)
        )
    },
    BUILD_REQUIRES    => {
        Test::Device::SerialPort => 0.05,
    },
    LICENSE           => 'perl',
    ($] >= 5.005      ## Add these new keywords supported since 5.005
        ? (
              ABSTRACT_FROM  => 'lib/Device/Inverter/Aurora.pm', # retrieve abstract from module
              AUTHOR         => 'Shannon Wynter'
        )
        : ()
    ),
);

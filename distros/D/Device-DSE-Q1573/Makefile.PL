

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Device::DSE::Q1573',
    VERSION_FROM => 'lib/Device/DSE/Q1573.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Read from DSE Q1573 / Metex Me-22 DMM',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Device::SerialPort' => 0.01,
          			 'POSIX' => 0.01,
          			 'Fcntl' => 0.01,
                    },
);

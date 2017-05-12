

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Device::WH1091',
    VERSION_FROM => 'lib/Device/WH1091.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Access data from the WH1081/1091 weather station.',
    PREREQ_PM    => {
                    },
);



use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Device::Kiln::Orton',
    VERSION_FROM => 'lib/Device/Kiln/Orton.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Utility module for retrieving conpyrometric cone charts',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);

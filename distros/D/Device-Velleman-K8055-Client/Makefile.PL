

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Device::Velleman::K8055::Client',
    VERSION_FROM => 'lib/Device/Velleman/K8055/Client.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Client for connecting to K8055::Server',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);

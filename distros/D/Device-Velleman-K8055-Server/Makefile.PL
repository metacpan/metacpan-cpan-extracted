

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Device::Velleman::K8055::Server',
    VERSION_FROM => 'lib/Device/Velleman/K8055/Server.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'IPCS Server for the K8055 Device',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);

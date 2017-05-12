use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Device::USB::MissileLauncher::RocketBaby',
    VERSION_FROM  => 'lib/Device/USB/MissileLauncher/RocketBaby.pm',
    PREREQ_PM     => { Device::USB => 0.21 },
    ($] >= 5.005 ? (
            ABSTRACT_FROM  => 'lib/Device/USB/MissileLauncher/RocketBaby.pm',
            AUTHOR         => 'Abe Masahiro <pen@thcomp.org>'
        ) : ()
    ),
);

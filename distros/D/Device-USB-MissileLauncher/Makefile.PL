use ExtUtils::MakeMaker;
WriteMakefile
(
          'NAME' => 'Device::USB::MissileLauncher',
          'VERSION_FROM' => 'lib/Device/USB/MissileLauncher.pm',
          'PREREQ_PM' => {
                           'Device::USB' => '0',
                           'Test::More' => '0'
                         },
          'PL_FILES' => {}
        )
;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::Local::Server',
    VERSION_FROM => 'lib/Geo/Local/Server.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/Geo/Local/Server.pm',
    PREREQ_PM    => {
                     'Test::Simple'     => 0.44,
                     'Package::New'     => 0,
                     'Config::IniFiles' => 0,
                     'Path::Class'      => 0,
                    },
    EXE_FILES    => [
                    qw{
                       scripts/is_daytime
                       scripts/is_nighttime
                       scripts/sunrise_time
                       scripts/sunset_time
                       scripts/local.coordinates
                      }
                    ],
);

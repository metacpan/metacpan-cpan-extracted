use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::Local::Server',
    VERSION_FROM => 'lib/Geo/Local/Server.pm',
    AUTHOR       => 'Michael R. Davis',
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
  'META_MERGE' => {
    'resources' => {
      'homepage' => 'https://github.com/mrdvt92/perl-Geo-Local-Server',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Local-Server/issues'
      },
      'repository' => {
        'url' => 'git@github.com:mrdvt92/perl-Geo-Local-Server.git',
        'type' => 'git',
        'web' => 'https://github.com/mrdvt92/perl-Geo-Local-Server.git'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  }
);

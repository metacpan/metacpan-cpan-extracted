use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => q{Geo::Inverse},
  VERSION_FROM  => 'lib/Geo/Inverse.pm',
  ABSTRACT_FROM => 'lib/Geo/Inverse.pm',
  PREREQ_PM     => {
                     'Test::Simple'        => 0.44,
                     'Test::Number::Delta' => 0,
                     'Package::New'        => 0,
                     'Geo::Constants'      => 0.04,
                     'Geo::Functions'      => 0.03,
                     'Geo::Ellipsoids'     => 0.09,
                   },
  'META_MERGE'  => {
                    'resources' => {
                      'repository' => {
                        'web' => 'https://github.com/mrdvt92/perl-Geo-Inverse.git',
                        'url' => 'git@github.com:mrdvt92/perl-Geo-Inverse.git',
                        'type' => 'git'
                      },
                      'homepage' => 'https://github.com/mrdvt92/perl-Geo-Inverse',
                      'bugtracker' => {
                        'web' => 'https://github.com/mrdvt92/perl-Geo-Inverse/issues'
                      }
                    },
                    'meta-spec' => {
                      'version' => 2
                    },
                   },
             );

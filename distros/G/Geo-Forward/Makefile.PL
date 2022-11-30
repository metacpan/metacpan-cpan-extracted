use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => q{Geo::Forward},
  VERSION_FROM  => 'lib/Geo/Forward.pm',
  ABSTRACT_FROM => 'lib/Geo/Forward.pm',
  PREREQ_PM     => {
                    'Test::Simple'    => 0.44,  #Test::More
                    'Geo::Constants'  => 0.04,
                    'Geo::Functions'  => 0.03,
                    'Geo::Ellipsoids' => 0.09,
                    'Package::New'    => 0,
                   },
  'META_MERGE'  => {
                    'resources' => {
                      'repository' => {
                        'web' => 'https://github.com/mrdvt92/perl-Geo-Forward.git',
                        'url' => 'git@github.com:mrdvt92/perl-Geo-Forward.git',
                        'type' => 'git'
                      },
                      'homepage' => 'https://github.com/mrdvt92/perl-Geo-Forward',
                      'bugtracker' => {
                        'web' => 'https://github.com/mrdvt92/perl-Geo-Forward/issues'
                      },
                    },
                    'meta-spec' => {
                      'version' => 2
                    },
                  },
             );

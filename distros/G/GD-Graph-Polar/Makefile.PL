use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'GD::Graph::Polar',
  VERSION_FROM  => 'lib/GD/Graph/Polar.pm',
  ABSTRACT_FROM => 'lib/GD/Graph/Polar.pm',
  PREREQ_PM     => {
                    'GD'                => 0,
                    'Geo::Constants'    => 0.04,
                    'Geo::Functions'    => 0.03,
                    'Test::Simple'      => 0.44, #test req
                    'List::Util'        => 0,
                    'Package::New'      => 0,
                   #'Graphics::ColorNames'=>0, #no longer required but nice to have
                   },
  'META_MERGE' => {
                   'resources' => {
                                   'repository' => {
                                                    'web' => 'https://github.com/mrdvt92/perl-GD-Graph-Polar.git',
                                                    'url' => 'git@github.com:mrdvt92/perl-GD-Graph-Polar.git',
                                                    'type' => 'git'
                                                   },
                                   'homepage' => 'https://github.com/mrdvt92/perl-GD-Graph-Polar',
                                   'bugtracker' => {
                                                    'web' => 'https://github.com/mrdvt92/perl-GD-Graph-Polar/issues'
                                                   },
                                  },
                   'meta-spec' => {
                                   'version' => 2
                                  },
                  },
             );

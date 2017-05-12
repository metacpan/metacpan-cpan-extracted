use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'GD::Graph::Polar',
  VERSION_FROM  => 'lib/GD/Graph/Polar.pm',
  ABSTRACT_FROM => 'lib/GD/Graph/Polar.pm',
  PREREQ_PM => {
                'GD'                => 0,
                'Geo::Constants'    => 0.04,
                'Geo::Functions'    => 0.03,
                'Test::Simple'      => 0.44, #test req
                'List::Util'        => 0,
                'Package::New'      => 0,
               #'Graphics::ColorNames'=>0, #no longer required but nice to have
               },
             );

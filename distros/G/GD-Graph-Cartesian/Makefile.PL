use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'GD::Graph::Cartesian',
  VERSION_FROM  => 'lib/GD/Graph/Cartesian.pm',
  ABSTRACT_FROM => 'lib/GD/Graph/Cartesian.pm',
  PREREQ_PM     => {
                     'Test::Simple'      => 0.44, #Tests
                     'Path::Class'       => 0,    #Tests
                     'GD'                => 2.02,
                     'List::Util'        => 0,
                     'List::MoreUtils'   => 0,
                     'Package::New'      => 0,
                   },
             );

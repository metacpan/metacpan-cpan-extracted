use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => q{Geo::Forward},
  VERSION_FROM  => 'lib/Geo/Forward.pm',
  ABSTRACT_FROM => 'lib/Geo/Forward.pm',
  PREREQ_PM => {
                 'Test::Simple'      => 0.44,  #Test::More
                 'Geo::Constants'    => 0.04, 
                 'Geo::Functions'    => 0.03, 
                 'Geo::Ellipsoids'   => 0.09, 
                 'Package::New'      => 0,
               },
             );

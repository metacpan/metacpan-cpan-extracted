use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Geo::Ellipsoids},
  VERSION_FROM => q{lib/Geo/Ellipsoids.pm},
  PREREQ_PM => {
                 strict         => 0,
                 vars           => 0,
                 constant       => 0,
                 Geo::Functions => 0.03,
                 Geo::Constants => 0.04,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Geo/Ellipsoids.pm',
                 ) : ()
               ),
             );

use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Geo::Horizon},
  VERSION_FROM => q{lib/Geo/Horizon.pm},
  PREREQ_PM => {
                 strict          => 0,
                 vars            => 0,
                 Math::Trig      => 0,
                 Geo::Ellipsoids => 0,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Geo/Horizon.pm',
                 ) : ()
               ),
             );

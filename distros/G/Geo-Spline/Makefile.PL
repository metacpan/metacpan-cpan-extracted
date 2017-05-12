use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Geo::Spline},
  VERSION_FROM => q{lib/Geo/Spline.pm},
  PREREQ_PM => {
                 strict          => 0,
                 vars            => 0,
                 constant        => 0,
                 Geo::Constants  => 0.04,
                 Geo::Functions  => 0.03,
                 Geo::Ellipsoids => 0.09,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Geo/Spline.pm',
                 ) : ()
               ),
             );

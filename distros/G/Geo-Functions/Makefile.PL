use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Geo::Functions},
  VERSION_FROM => q{lib/Geo/Functions.pm},
  PREREQ_PM => {
                 strict            => 0,
                 vars              => 0,
                 Exporter          => 0,
                 Geo::Constants    => 0.06,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Geo/Functions.pm',
                 ) : ()
               ),
             );

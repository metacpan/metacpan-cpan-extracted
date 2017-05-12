use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Geo::Constants},
  VERSION_FROM => q{lib/Geo/Constants.pm},
  PREREQ_PM => {
                 strict            => 0,
                 vars              => 0,
                 Exporter          => 0,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Geo/Constants.pm',
                 ) : ()
               ),
             );

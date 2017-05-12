use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{GPS::SpaceTrack},
  VERSION_FROM => q{lib/GPS/SpaceTrack.pm},
  PREREQ_PM => {
                 strict               => 0,
                 vars                 => 0,
                 Astro::Coord::ECI    => 0,
                 Astro::Coord::ECI::TLE => 0,
                 Astro::SpaceTrack    => 0,
                 Net::GPSD::Satellite => 0.30,
                 Geo::Functions       => 0.05,
                 Time::HiRes          => 0,
                 GPS::PRN             => 0.04,
                 GD::Graph::Polar     => 0.09,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/GPS/SpaceTrack.pm',
                 ) : ()
               ),
             );

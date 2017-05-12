use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::Sun',
    VERSION_FROM => 'lib/Geo/Sun.pm',
    AUTHOR       => 'Michael R. Davis (domain=>stopllc,tld=>com,account=>mdavis)',
    ABSTRACT_FROM=> 'lib/Geo/Sun.pm',
    LICENSE      => 'bsd',
    PREREQ_PM    => {
                     'Test::Simple'           => 0.44,
                     'Test::More'             => 0,
                     'Test::Number::Delta'    => 0,
                     'vars'                   => 0,
                     'strict'                 => 0,
                     'warnings'               => 0,
                     'Astro::Coord::ECI::Sun' => 0,
                     'DateTime'               => 0,
                     'Geo::Constants'         => 0,
                     'Geo::Functions'         => 0,
                     'Geo::Ellipsoids'        => 0,
                     'GPS::Point'             => 0,
                     'Geo::Inverse'           => 0.05,
                    },
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Geo::Coordinates::UTM',
    ABSTRACT       => 'Convert LatLon to UTM and vice versa',
    AUTHOR         => 'Graham Crookham (grahamc@cpan.org)',
    VERSION_FROM   => 'UTM.pm', # finds $VERSION
);

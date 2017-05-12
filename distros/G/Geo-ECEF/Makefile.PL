#use 5.008;  #  This was left over from the sickel version
             #  but I don't think it is needed. -mrdvt92
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::ECEF',
    VERSION_FROM      => 'lib/Geo/ECEF.pm',
    PREREQ_PM         => {
                          warnings          => 0,
                          strict            => 0,
                          Geo::Functions    => 0.03,
                          Geo::Ellipsoids   => 0.14,
                         },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Geo/ECEF.pm',
       AUTHOR         => 'Morten Sickel <morten@sickel.net> & Michael R. Davis (mrdvt92)') : ()),
);

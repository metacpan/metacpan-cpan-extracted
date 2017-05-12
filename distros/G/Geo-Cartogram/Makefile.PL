use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Cartogram',
    VERSION_FROM      => 'lib/Geo/Cartogram.pm', # finds $VERSION
    PREREQ_PM         => { Geo::ShapeFile => 2.51 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Cartogram.pm', # retrieve abstract from module
       AUTHOR         => 'Luis Fagundes <lhfagundes@gmail.com>') : ()),
);

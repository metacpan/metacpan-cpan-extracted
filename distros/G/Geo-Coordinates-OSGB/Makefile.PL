use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME             => 'Geo::Coordinates::OSGB',
  AUTHOR           => 'Toby Thurston',
  VERSION_FROM     => 'lib/Geo/Coordinates/OSGB.pm',
  ABSTRACT_FROM    => 'lib/Geo/Coordinates/OSGB.pm',
  MIN_PERL_VERSION => '5.008',
  dist             => {TARFLAGS => '-cvf'},
);




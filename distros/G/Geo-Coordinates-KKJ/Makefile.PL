use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Coordinates::KKJ',
    VERSION_FROM      => 'lib/Geo/Coordinates/KKJ.pm', # finds $VERSION
    PREREQ_PM         => { Test::Exception => 0.27 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Coordinates/KKJ.pm', # retrieve abstract from module
       AUTHOR         => 'Josep Roca <quelcom@gmail.com>') : ()),
);

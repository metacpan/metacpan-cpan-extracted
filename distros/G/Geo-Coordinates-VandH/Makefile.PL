use 5.00004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Coordinates::VandH',
    VERSION_FROM      => 'VandH.pm', # finds $VERSION
    PREREQ_PM         => {Math::Trig => 0, Math::Complex => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'VandH.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Timmins <paul@timmins.net>') : ()),
);

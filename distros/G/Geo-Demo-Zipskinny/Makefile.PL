use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Demo::Zipskinny',
    VERSION_FROM      => 'lib/Geo/Demo/Zipskinny.pm', # finds $VERSION
    PREREQ_PM         => { 'LWP::Simple' => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Demo/Zipskinny.pm', # retrieve abstract from module
       AUTHOR         => 'Allen Day <allenday@ucla.edu>') : ()),
);

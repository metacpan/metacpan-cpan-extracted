use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Location::Area::DoCoMo::iArea',
    VERSION_FROM      => 'lib/Location/Area/DoCoMo/iArea.pm', # finds $VERSION
    PREREQ_PM         => { Location::GeoTool => 1.97 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Location/Area/DoCoMo/iArea.pm', # retrieve abstract from module
       AUTHOR         => 'OHTSUKA Ko-hei <kotsuka@spacetag.jp>') : ()),
);

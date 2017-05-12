use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Cloudmade',
    VERSION_FROM      => 'lib/Geo/Cloudmade.pm', # finds $VERSION
    PREREQ_PM         => { JSON => 2.0, LWP => 5.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Cloudmade.pm', # retrieve abstract from module
       AUTHOR         => ['Dmytro Gorbunov <dmitro.gorbunov@gmail.com>','Tim Bunce <Tim.Bunce@pobox.com>']) : ()),
);

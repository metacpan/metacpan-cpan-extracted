use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Geo::Caching',
    'VERSION_FROM'	=> 'Caching.pm', # finds $VERSION
    'PREREQ_PM'		=> {WWW::Mechanize => q[1.12],
			    Geo::Cache => 0.20,
			    Geo::Gpx => 0.10 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Caching.pm', # retrieve abstract from module
       AUTHOR     => 'Casey Lee <cplee@cplee.org>') : ()),
);

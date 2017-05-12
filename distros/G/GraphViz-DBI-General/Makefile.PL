use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GraphViz::DBI::General',
    VERSION_FROM      => 'lib/GraphViz/DBI/General.pm', # finds $VERSION
    PREREQ_PM         => { GraphViz::DBI => 0,
                           GraphViz => 0,
                           DBI => 0, 
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GraphViz/DBI/General.pm', # retrieve abstract from module
       AUTHOR         => 'Joseph Brenner <doom@kzsu.stanford.edu>') : ()),
);

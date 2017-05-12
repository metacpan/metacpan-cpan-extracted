use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GRID::Cluster',
    VERSION_FROM      => 'lib/GRID/Cluster.pm', # finds $VERSION
    PREREQ_PM         => { 'GRID::Machine' => '0.110', 'Term::Prompt' => '0' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GRID/Cluster.pm', # retrieve abstract from module
       AUTHOR         => 'Eduardo Segredo <edusegre@gmail.com>') : ()),
);

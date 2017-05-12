use ExtUtils::MakeMaker;
  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Geo::Postcodes',
    'VERSION_FROM'	=> 'lib/Geo/Postcodes.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PL_FILES'          => {}, # Property of Build.pm
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Geo/Postcodes.pm', # retrieve abstract from module
       AUTHOR     => 'Arne Sommer <perl@bbop.org>') : ()),
);

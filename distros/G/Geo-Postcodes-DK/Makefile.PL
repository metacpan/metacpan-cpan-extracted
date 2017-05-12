use ExtUtils::MakeMaker;
  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Geo::Postcodes::DK',
    'VERSION_FROM'	=> 'lib/Geo/Postcodes/DK.pm', # finds $VERSION
    'PREREQ_PM'		=> { Geo::Postcodes => 0.31 },
    'PL_FILES'          => {}, # Property of Build.pm
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Geo/Postcodes/DK.pm', # retrieve abstract from module
       AUTHOR     => 'Arne Sommer <perl@bbop.org>') : ()),
);

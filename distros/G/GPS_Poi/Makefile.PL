use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GPS::Poi',
    VERSION_FROM      => 'lib/GPS/Poi.pm', # finds $VERSION
    PREREQ_PM         => { 
                          Class::Std::Utils => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GPS/Poi.pm', # retrieve abstract from module
       AUTHOR         => 'Eric German <germanlinux@yahoo.fr>') : ()),
);

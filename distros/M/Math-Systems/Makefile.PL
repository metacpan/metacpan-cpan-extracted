use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'                => 'Math::Systems',
    'VERSION_FROM'        => 'Systems.pm', # finds $VERSION
    'PREREQ_PM'                => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Systems.pm', # retrieve abstract from module
       AUTHOR     => 'Will Gunther <williamgunther@aol.com>') : ()),
);
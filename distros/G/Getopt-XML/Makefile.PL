use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Getopt::XML',
    VERSION_FROM      => 'lib/Getopt/XML.pm', # finds $VERSION
    PREREQ_PM         => { Getopt::Long => 2.37,
                           XML::TreePP => 0.33,
                           XML::TreePP::XMLPath => 0.56,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Getopt/XML.pm', # retrieve abstract from module
       AUTHOR         => 'Russell E Glaue') : ()),
);

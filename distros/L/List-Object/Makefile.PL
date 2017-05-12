use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'List::Object',
    VERSION_FROM      => 'lib/List/Object.pm', # finds $VERSION
    PREREQ_PM         => {Carp      => "0.0",
                          Exporter  => "0.0"}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/List/Object.pm', # retrieve abstract from module
       AUTHOR         => 'Steven Hilton <mshiltonj@localdomain>') : ()),
);

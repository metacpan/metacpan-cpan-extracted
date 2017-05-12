use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Manipulator',
    VERSION_FROM      => 'Manipulator.pm', # finds $VERSION
    PREREQ_PM         => {HTML::Parser => 3}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Manipulator.pm', # retrieve abstract from module
       AUTHOR         => 'Thilo Planz') : ()),
);

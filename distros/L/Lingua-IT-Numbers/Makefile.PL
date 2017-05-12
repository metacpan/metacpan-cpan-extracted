use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::IT::Numbers',
    VERSION_FROM      => 'lib/Lingua/IT/Numbers.pm', # finds $VERSION
    PREREQ_PM         => {Regexp::Common::number => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/IT/Numbers.pm', # retrieve abstract from module
       AUTHOR         => 'Frodo Baggins <hobbit@c47.org>') : ()),
);

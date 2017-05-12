use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::PBMlib',
    VERSION_FROM      => 'lib/Image/PBMlib.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/PBMlib.pm', # retrieve abstract from module
       AUTHOR         => 'Benjamin Elijah Griffin / Eli the Bearded <elijah@cpan.org>') : ()),
);

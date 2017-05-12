use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MFor',
    VERSION_FROM      => 'lib/MFor.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.008 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MFor.pm', # retrieve abstract from module
       AUTHOR         => 'Lin Yo-An <cornelius.howl@gmail.com>') : ()),
);

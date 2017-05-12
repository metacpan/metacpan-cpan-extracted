use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::TagTree',
    VERSION_FROM      => 'lib/HTML/TagTree.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'lib/HTML/TagTree.pm', # retrieve abstract from module
       AUTHOR         => 'daniel debrito <ddebrito@gmail.com>') : ()),
);

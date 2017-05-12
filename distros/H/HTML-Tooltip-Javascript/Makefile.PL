use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Tooltip::Javascript',
    VERSION_FROM      => 'lib/HTML/Tooltip/Javascript.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Tooltip/Javascript.pm', # retrieve abstract from module
       AUTHOR         => 'Becky Alcorn <becky@unisolve.com.au>') : ()),
);

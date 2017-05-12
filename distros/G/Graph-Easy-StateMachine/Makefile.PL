use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Graph::Easy::StateMachine',
    VERSION_FROM      => 'lib/Graph/Easy/StateMachine.pm', # finds $VERSION
    PREREQ_PM         => {Graph::Easy => 0.64, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Graph/Easy/StateMachine.pm', # retrieve abstract from module
       AUTHOR         => 'David Nicol <davidnico@cpan.org>') : ()),
);

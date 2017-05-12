use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::Fork::Simple',
    VERSION_FROM      => 'lib/IPC/Fork/Simple.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPC/Fork/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'John Eaglesham <jeagle@cpan.org>') : ()),
);

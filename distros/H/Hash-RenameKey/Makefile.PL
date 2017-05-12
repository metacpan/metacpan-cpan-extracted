use 5.001000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Hash::RenameKey',
    VERSION_FROM      => 'lib/Hash/RenameKey.pm', # finds $VERSION
    PREREQ_PM         => { 'Class::Accessor' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Hash/RenameKey.pm', # retrieve abstract from module
       AUTHOR         => 'Jason Clifford <jason@ukfsn.org>') : ()),
);

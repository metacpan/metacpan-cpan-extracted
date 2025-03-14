use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IO::BufferedSelect2',
    VERSION_FROM      => 'lib/IO/BufferedSelect2.pm', # finds $VERSION
    PREREQ_PM         => { 'Linux::Inotify2' => 2}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/BufferedSelect2.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Drake <cdrake@cpan.org>') : ()),
);

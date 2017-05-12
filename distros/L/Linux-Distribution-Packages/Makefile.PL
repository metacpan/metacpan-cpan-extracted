use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Linux::Distribution::Packages',
    VERSION_FROM      => 'lib/Linux/Distribution/Packages.pm', # finds $VERSION
    PREREQ_PM         => { 'Linux::Distribution' => '0.14', 'XML::Writer' => '0' }, # e.g., Module::Name => 1.1
    PREREQ_FATAL      => '1',
    ($] >= 5.005 ?     ## I am not actually sure about this version
      (ABSTRACT_FROM  => 'lib/Linux/Distribution/Packages.pm', # retrieve abstract from module
       AUTHOR         => 'Judith Lebzelter <judith@osdl.org>') : ()),
);

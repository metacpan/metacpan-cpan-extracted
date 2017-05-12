#use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Jtag::PP',
    VERSION_FROM      => 'lib/Device/Jtag/PP.pm', # finds $VERSION
    PREREQ_PM         => {Device::ParallelPort => 1.00}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Jtag/PP.pm', # retrieve abstract from module
       AUTHOR         => 'Toby Deitrich <tdeitrich@cpan.org>') : ()),
);

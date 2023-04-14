use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Evo::Maple',
    VERSION_FROM      => 'lib/Evo/Maple.pm', # finds $VERSION
    PREREQ_PM         => { Evo::Parser => 0.1.1, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Evo/Maple.pm', # retrieve abstract from module
       AUTHOR         => 'koboldwiz <koboldwiz@cpan.org>') : ()),
);

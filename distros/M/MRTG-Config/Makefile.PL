use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MRTG::Config',
    VERSION_FROM      => 'lib/MRTG/Config.pm', # finds $VERSION
    PREREQ_PM         => { DBM::Deep => 0.94 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MRTG/Config.pm', # retrieve abstract from module
       AUTHOR         => 'Stephen R. Scaffidi <sscaffidi@cpan.org>') : ()),
);

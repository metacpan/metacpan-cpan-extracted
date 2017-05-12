use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'List::Util::WeightedChoice',
    VERSION_FROM      => 'lib/List/Util/WeightedChoice.pm', # finds $VERSION
    PREREQ_PM         => { 'Params::Validate' => 0.9
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/List/Util/WeightedChoice.pm', # retrieve abstract from module
       AUTHOR         => 'Danny Sadinoff <danny-cpan@sadinoff.com>') : ()),
);

use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FactorOracle',
    VERSION_FROM      => 'lib/FactorOracle.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
);

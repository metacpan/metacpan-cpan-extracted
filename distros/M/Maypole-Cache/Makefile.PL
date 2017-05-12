use 5.00005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Maypole::Cache',
    VERSION_FROM      => 'Cache.pm', # finds $VERSION
    PREREQ_PM         => {
        Maypole => 1.4,
        Cache::Cache => 0,
        Class::ISA => 0,
        Digest::SHA1 => 0,
    }
);

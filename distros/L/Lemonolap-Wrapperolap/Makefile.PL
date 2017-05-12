use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonolap::Wrapperolap',
    VERSION_FROM      => 'lib/Lemonolap/Wrapperolap.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
);

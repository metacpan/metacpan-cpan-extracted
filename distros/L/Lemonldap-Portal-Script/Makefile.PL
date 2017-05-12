use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::Portal::Script',
    VERSION_FROM      => 'lib/Lemonldap/Portal/Script.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
);

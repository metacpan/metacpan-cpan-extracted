use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::Handlers::Generic',
    VERSION_FROM      => 'lib/Lemonldap/Handlers/Generic4a2.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
);

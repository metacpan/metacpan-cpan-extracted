use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::Config::Parameters',
    VERSION_FROM      => 'lib/Lemonldap/Config/Parameters.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
      (ABSTRACT_FROM  => 'lib/Lemonldap/Config/Parameters.pm', # retrieve abstract from module
       AUTHOR         => 'Eric German <gemanlinux@yahoo.fr>') )
;

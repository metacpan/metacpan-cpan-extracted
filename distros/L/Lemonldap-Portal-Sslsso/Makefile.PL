use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::Portal::Sslsso',
    VERSION_FROM      => 'Sslsso.pm', # finds $VERSION
    PREREQ_PM         => {Net::LDAP => '0.0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Sslsso.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@localdomain>') : ()),
);

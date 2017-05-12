use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::Portal::Authntsso',
    VERSION_FROM      => 'Authntsso.pm', # finds $VERSION
    PREREQ_PM         => {Authen::Smb => '0.0' ,
                          Net::LDAP =>'0.0',
                          MIME::Base64 => '0.0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Authntsso.pm', # retrieve abstract from module
       AUTHOR         => 'Eric German <germanlinux@yahoo.fr>') : ()),
);

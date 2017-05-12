use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::Portal::Session',
    VERSION_FROM      => 'lib/Lemonldap/Portal/Session.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    ( ABSTRACT  => 'seesion parser for  lemonldap websso', 
       AUTHOR         => 'Eric GERMAN <germanlinux@yahoo.fr>') : ()),
   );

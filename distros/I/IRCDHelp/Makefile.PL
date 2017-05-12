use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Component::IRC::Plugin::IRCDHelp',
    VERSION_FROM      => 'lib/POE/Component/IRC/Plugin/IRCDHelp.pm', # finds $VERSION
    PREREQ_PM         => {IRCDHelp => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Component/IRC/Plugin/IRCDHelp.pm', # retrieve abstract from module
       AUTHOR         => 'scilley <scilley@cpan.org>') : ()),
);

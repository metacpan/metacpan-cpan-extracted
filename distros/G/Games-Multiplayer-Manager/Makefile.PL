use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::Multiplayer::Manager',
    VERSION_FROM      => 'lib/Games/Multiplayer/Manager.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Multiplayer/Manager.pm', # retrieve abstract from module
       AUTHOR         => 'Cerone Kirsle <kirsle@cpan.org>') : ()),
);

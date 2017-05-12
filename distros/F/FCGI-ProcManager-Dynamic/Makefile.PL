use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FCGI::ProcManager::Dynamic',
    VERSION_FROM      => 'lib/FCGI/ProcManager/Dynamic.pm', # finds $VERSION
    PREREQ_PM         => { FCGI::ProcManager => 0.18, Time::HiRes => 0, IPC::SysV => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/FCGI/ProcManager/Dynamic.pm', # retrieve abstract from module
       AUTHOR         => 'Andrey Velikoredchanin <andy@andyhost.ru>') : ()),
);

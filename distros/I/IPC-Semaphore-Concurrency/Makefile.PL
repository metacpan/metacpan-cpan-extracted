use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::Semaphore::Concurrency',
    VERSION_FROM      => 'lib/IPC/Semaphore/Concurrency.pm', # finds $VERSION
    PREREQ_PM         => {
	    Carp              => 0,
	    POSIX             => 0,
	    IPC::SysV         => 0,
	    IPC::Semaphore    => 0,
	    Test::More 	      => 0,
	    Exporter          => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPC/Semaphore/Concurrency.pm', # retrieve abstract from module
       AUTHOR         => 'Thomas Guyot-Sionnest <tguyot@gmail.com>') : ()),
);

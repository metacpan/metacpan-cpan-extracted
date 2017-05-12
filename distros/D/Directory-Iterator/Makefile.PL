use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Directory::Iterator',
    VERSION_FROM      => 'lib/Directory/Iterator.pm', # finds $VERSION
    PREREQ_PM         => {
	Directory::Iterator::PP => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Directory/Iterator.pm', # retrieve abstract from module
       AUTHOR         => 'Steve Sanbeg') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
	  (LICENSE		=> 'perl') : ()),
);

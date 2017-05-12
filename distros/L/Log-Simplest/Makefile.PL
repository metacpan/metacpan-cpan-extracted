use 5.008000;
use ExtUtils::MakeMaker;
# $Id: Makefile.PL 2461 2009-03-20 05:05:25Z dk $
# $URL: svn://svn/dmytro/Development/perl/modules/Log-Simplest/trunk/Makefile.PL $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Log::Simplest',
    VERSION_FROM      => 'lib/Log/Simplest.pm', # finds $VERSION
    PREREQ_PM         => {
			  FileHandle => 2.01,
			  POSIX => 1.09
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Log/Simplest.pm', # retrieve abstract from module
       AUTHOR         => 'Dmytro Koval\'ov <dmytro.kolalov@gmail.com>') : ()),
);

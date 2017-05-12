#
# $Id: Makefile.PL,v 0.70 2005/08/09 15:47:00 dankogai Exp $
#

$^O =~ /darwin/o or die "$^O is not darwin!";

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# makemorefiles();

@EXE = qw(
	  pcpmac
	  pmvmac
	  psetfinfo
	  pgetfinfo 
	  psync
);

WriteMakefile
    (
     'NAME'		=> 'MacOSX::File',
     'VERSION_FROM'	=> 'File.pm', # finds $VERSION
     'PREREQ_PM'	=> {}, # e.g., Module::Name => 1.1
     'EXE_FILES'        => [map {"bin/$_"} @EXE],
     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'File.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Kogai <dankogai@dan.co.jp>') : ()),
     INSTALLSCRIPT      => "/usr/local/bin",
     INSTALLMAN1DIR     => "/usr/local/share/man/man1",
     INSTALLMAN3DIR     => "/usr/local/share/man/man3",
);

sub makemorefiles{
    warn "-- Making MoreFiles a priori\n";
    chdir 'MoreFiles';
    system 'make';
    chdir '..';
    warn "-- Making MoreFiles: done\n";
}


#=============================================================================
#	File:	Makefile.PL
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer.
#	Date:	2001/04/18
#	Use:	Makefile generator for FameHLI::API::HLI
#=============================================================================
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'FameHLI::API::HLI',
    'VERSION_FROM'	=> 'HLI.pm',
    'PREREQ_PM'		=> {},
    'LIBS'		=> ["-L$ENV{HLI} -lchli"],
	'OBJECT'	=> 'HLI.o',
    'DEFINE'		=> '',
    'INC'		=> "-I$ENV{HLI}",
);

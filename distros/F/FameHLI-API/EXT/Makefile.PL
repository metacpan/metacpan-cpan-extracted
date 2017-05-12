#=============================================================================
#	File:	Makefile.PL
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer.
#	Date:	2001/04/18
#	Use:	Create Makefile for FameHLI::API::EXT stuff
#=============================================================================
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if (!$ENV{HLI}) {
	die("Please define 'HLI' before continuing.\n");
}
WriteMakefile(
    'NAME'	=> 'FameHLI::API::EXT',
    'VERSION_FROM' => 'EXT.pm',
    'LIBS'	=> ["-L$ENV{HLI} -lchli"],
    'OBJECT' => 'EXT.o',
    'DEFINE'	=> $ENV{STATICFAME}?'-DCFMINI_EVERYWHERE':'',
    'INC'	=> "-I$ENV{HLI}",
);


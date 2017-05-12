#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=>	'MegaDistro',
	VERSION_FROM	=>	'lib/MegaDistro.pm',
	PREREQ_PM	=>	{
				     CPANPLUS             =>     0.0562,
				     Module::CoreList     =>     2.02,
				     ExtUtils::MakeMaker  =>     6.17,
				     Archive::Tar         =>     0,
				     File::Spec           =>     0.80,
				},
	EXE_FILES	=>	[
				     'bin/megadistro',
				],
	
	     );

#!/usr/bin/perl -w
use ExtUtils::MakeMaker;

WriteMakefile(
	ABSTRACT		=> 	'Simple and useful log module with fun inside ;)',
	NAME			=>	'Log::Funlog',
	VERSION_FROM	=>	"lib/Log/Funlog.pm",
	AUTHOR			=>	'Gabriel Guillon <korsani(removeme)@free(removeme).fr(removeagain)>',
);
1;

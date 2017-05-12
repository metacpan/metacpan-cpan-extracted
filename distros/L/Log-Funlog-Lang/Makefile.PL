#!/usr/bin/perl -w
use ExtUtils::MakeMaker;

WriteMakefile(
	ABSTRACT		=> 	'Language module used by Log::Funlog',
	NAME			=>	'Log::Funlog::Lang',
	VERSION_FROM	=>	"lib/Log/Funlog/Lang.pm",
	AUTHOR			=>	'Gabriel Guillon <korsani(removeme)@free(removeme).fr(removeagain)>',
);
1;

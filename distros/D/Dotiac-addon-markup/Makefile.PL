#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL::Addon::markup',
	VERSION_FROM=>'lib/Dotiac/DTL/Addon/markup.pm',
	PREREQ_PM=>{
                         'Dotiac::DTL'=>0.4,
                         'Text::Textile'=>0,
                         'Text::Markdown'=>0,
#                         'Text::Restructured'=>0,
		 }
);

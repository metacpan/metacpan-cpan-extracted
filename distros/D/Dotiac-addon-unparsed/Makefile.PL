#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL::Addon::unparsed',
	VERSION_FROM=>'lib/Dotiac/DTL/Addon/unparsed.pm',
	PREREQ_PM=>{
                         'Dotiac::DTL'=>0.2,
		 }
);

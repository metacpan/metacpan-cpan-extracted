#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL::Addon::case_insensitive',
	VERSION_FROM=>'lib/Dotiac/DTL/Addon/case_insensitive.pm',
	PREREQ_PM=>{
                         'Dotiac::DTL'=>0.5,
		 }
);

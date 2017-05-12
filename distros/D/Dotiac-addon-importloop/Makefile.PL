#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL::Addon::importloop',
	VERSION_FROM=>'lib/Dotiac/DTL/Addon/importloop.pm',
	PREREQ_PM=>{
                         'Dotiac::DTL'=>0.5,
		 }
);

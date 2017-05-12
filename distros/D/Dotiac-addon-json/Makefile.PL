#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL::Addon::json',
	VERSION_FROM=>'lib/Dotiac/DTL/Addon/json.pm',
	PREREQ_PM=>{
                         'Dotiac::DTL'=>0.4,
                         'JSON'=>2,
		 }
);

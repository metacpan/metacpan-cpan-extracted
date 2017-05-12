#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL::Addon::html_template',
	VERSION_FROM=>'lib/Dotiac/DTL/Addon/html_template.pm',
	PREREQ_PM=>{
                         'Dotiac::DTL'=>0.5,
			 'Carp'=>0,
			 'File::Spec'=>0,
			 'Scalar::Util'=>0,
			 'File::Basename'=>0,
			 'Dotiac::DTL::Addon::case_insensitive'=> 0.3,
			 'Dotiac::DTL::Addon::importloop'=> 0.2,
		 }
);

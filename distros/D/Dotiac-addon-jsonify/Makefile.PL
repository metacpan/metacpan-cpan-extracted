#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL::Addon::jsonify',
	VERSION_FROM=>'lib/Dotiac/DTL/Addon/jsonify.pm',
	PREREQ_PM=>{
                         'Dotiac::DTL'=>0.4,
                         'JSON'=>2,
		 }
);

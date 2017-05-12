#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Dotiac::DTL',
	VERSION_FROM=>'lib/Dotiac/DTL.pm',
	PREREQ_PM=>{
                         'Scalar::Util' => 0,
			 'Data::Dumper' => 0,
			 'File::Temp' => 0,
			 'File::Basename' => 0,
			 'File::Spec' => 0,
			 'Carp'=>0,
			 'Digest::MD5'=>0,
		 }
);

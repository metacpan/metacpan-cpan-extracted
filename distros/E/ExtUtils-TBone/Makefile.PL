#!/usr/bin/perl
use ExtUtils::MakeMaker;

#------------------------------------------------------------
# Makefile:
#------------------------------------------------------------

# Write the Makefile:
WriteMakefile(
	      NAME         => 'ExtUtils::TBone',
	      VERSION_FROM => "./lib/ExtUtils/TBone.pm",
	      'dist'       => {
		  PREOP    => "cvu_perl_preop -m ExtUtils::TBone",
		  COMPRESS => 'gzip',
		  SUFFIX   => 'gz',
	      }
	      );



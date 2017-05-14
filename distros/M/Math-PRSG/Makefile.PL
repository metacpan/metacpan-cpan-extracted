#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Math::PRSG',
	'DISTNAME' => 'Math-PRSG',
	'VERSION' => '1.0',
	'OBJECT' => 'PRSG.o prsg.o',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);

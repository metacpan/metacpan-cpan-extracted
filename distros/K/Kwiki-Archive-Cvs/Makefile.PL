#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Kwiki::Archive::Cvs',
	'VERSION' => '0.104',

	PREREQ_PM   => {
		'Kwiki::Archive' => 0.39
	},

	NO_META => 1
);

#!/usr/bin/perl

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'            => 'Decode::Source',
	'VERSION_FROM'    => 'Source.pm',       # finds $VERSION
	'PREREQ_PM'       => {},                # e.g., Module::Name => 1.1
	ABSTRACT_FROM     => 'Source.pm',       # retrieve abstract from module
	AUTHOR            => 'Magnus Håkansson <magnus@mbox604.swipnet.se>',
);

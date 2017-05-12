#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile (ABSTRACT => 'Markup::MatchTree - For building trees to be compared to C<Markup::Tree>s',
	       AUTHOR => 'BPrudent (Brandon Prudent)',
	       DISTNAME => 'Markup',
	       NAME => 'Markup::MatchTree',
	       PREREQ_PM => {
	       		'Markup::Tree' => 0
	       },
	       INSTALLMAN3DIR => 'none',
	       VERSION => v1.0.0);

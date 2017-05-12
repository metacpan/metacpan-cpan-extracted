#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile (ABSTRACT => 'Markup::Content - Extract content markup information from a markup document',
	       AUTHOR => 'BPrudent (Brandon Prudent)',
	       DISTNAME => 'Markup',
	       NAME => 'Markup::Content',
	       PREREQ_PM => {
	       		'Markup::Tree' => 0,
			'Markup::TreeNode' => 0,
			'Markup::MatchTree' => 0
	       },
	       INSTALLMAN3DIR => 'none',
	       VERSION => v1.0.0);

#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile (ABSTRACT => 'Markup::MatchNode - Comparison object of Markup::TreeNode',
	       AUTHOR => 'BPrudent (Brandon Prudent)',
	       DISTNAME => 'Markup',
	       NAME => 'Markup::MatchNode',
	       PREREQ_PM => {
	       		'Markup::TreeNode' => 0
	       },
	       INSTALLMAN3DIR => 'none',
	       VERSION => v1.0.0);

#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile (ABSTRACT => 'Markup::Tree - Builds an easy syntax tree from a local or remote file',
	       AUTHOR => 'BPrudent (Brandon Prudent)',
	       DISTNAME => 'Markup',
	       NAME => 'Markup::Tree',
	       PREREQ_PM => {
		   'XML::Parser' => 0,
		   'HTML::TreeBuilder' => 0,
		   'Markup::TreeNode' => 0,
		   'File::Temp' => 0,
		   'LWP::Simple' => 0
	       },
	       INSTALLMAN3DIR => 'none',
	       VERSION => v1.2.1);

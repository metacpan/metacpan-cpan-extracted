#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile (ABSTRACT => 'Markup::TreeNode - Represents nodes on the Markup::Tree',
	       AUTHOR => 'BPrudent (Brandon Prudent)',
	       DISTNAME => 'Markup',
	       NAME => 'Markup::TreeNode',
	       INSTALLMAN3DIR => 'none',
	       VERSION => v1.1.6);

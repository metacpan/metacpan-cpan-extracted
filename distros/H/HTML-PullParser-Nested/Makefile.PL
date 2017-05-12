#!/usr/bin/perl
# $Id: Makefile.PL 4644 2010-03-09 18:03:56Z chris $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'HTML::PullParser::Nested',
    VERSION_FROM    => 'lib/HTML/PullParser/Nested.pm',
    ABSTRACT_FROM   => 'lib/HTML/PullParser/Nested.pm', 
    AUTHOR          => 'Christopher Key <cjk32@cam.ac.uk>', 
    LICENSE         => 'perl', 
    PREREQ_PM       => {
	'HTML::PullParser' => 0, 
    }, 
    );

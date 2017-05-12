#!/usr/bin/perl
use ExtUtils::MakeMaker;

@if5005 = (
    'AUTHOR' => 'Jeremy Cortner <jcortner@cvol.net>',
    'ABSTRACT' => 'allows for list comprehensions in Perl.',
) if $] ge '5.005';

WriteMakefile(
    NAME		    => 'List::Comprehensions',
    VERSION_FROM	    => 'lib/List/Comprehensions.pm',
    PREREQ_PM		    => {
	'Alias'		    => 0,
	'Array::RefElem'    => 0,
	'PadWalker'	    => 0
    }, @if5005
);

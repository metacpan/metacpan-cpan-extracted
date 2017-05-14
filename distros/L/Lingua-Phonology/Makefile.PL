#!/usr/bin/perl -w

use ExtUtils::MakeMaker qw(WriteMakefile prompt);

# Note that prereqs are not listed, and have to be managed manually in the meta
# files

WriteMakefile (
	NAME			=> 'Lingua::Phonology',
	ABSTRACT_FROM 	=> 'Phonology.pm',
	VERSION_FROM 	=> 'Phonology.pm',
    NO_META         => 1
);

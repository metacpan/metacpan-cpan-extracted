#!/usr/bin/perl -w

use ExtUtils::MakeMaker qw(WriteMakefile prompt);

our $prereqs = {
    XML::Simple => 2.08,
    Parse::RecDescent => 1.0,
    B::Deparse => 0.63
};

WriteMakefile (
	NAME			=> 'Lingua::Phonology',
	ABSTRACT_FROM 	=> 'Phonology.pm',
	VERSION_FROM 	=> 'Phonology.pm',
	PREREQ_PM		=> $prereqs
);

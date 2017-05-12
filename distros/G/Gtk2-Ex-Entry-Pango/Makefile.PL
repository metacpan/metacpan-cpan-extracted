#!/usr/bin/perl

use strict;
use warnings;
use 5.006000;

use ExtUtils::MakeMaker;

my $file = 'lib/Gtk2/Ex/Entry/Pango.pm';

WriteMakefile(
	NAME           => 'Gtk2::Ex::Entry::Pango',
	VERSION_FROM   => $file,
	ABSTRACT_FROM  => $file,
	AUTHOR         => 'Emmanuel Rodriguez <potyl@cpan.org>',

	PREREQ_PM      => {
		'Gtk2'         => '1.100', # Pango was first introduced here
		'Gtk2::Pango'  => 0,
	},
);

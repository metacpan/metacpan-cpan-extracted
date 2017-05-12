use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::Spec;
use Data::Dumper;


sub main {
	# Create the Makefile
	my @args = (
		AUTHOR        => 'Thierry Vignaud <tvignaud@cpan.org>',
		NAME          => 'Gtk3::SimpleList',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk3', 'SimpleList.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk3', 'SimpleList.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => {
			'Gtk3'                        => 0,
		},
		PREREQ_FATAL  => 1,

		META_MERGE => {
			resources => {
				homepage    => 'https://github.com/potyl/perl-Gtk3-SimpleList',
				bucktracker => 'https://github.com/potyl/perl-Gtk3-SimpleList/issues',
				repository  => 'https://github.com/potyl/perl-Gtk3-SimpleList',
			},
		},
	);
	WriteMakefile(@args);


	return 0;
}


exit main() unless caller;


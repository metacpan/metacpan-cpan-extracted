use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::Spec;
use Data::Dumper;


sub main {
	# Create the Makefile
	my @args = (
		AUTHOR        => 'Thierry Vignaud <tvignaud@cpan.org>',
		NAME          => 'Gtk3::Helper',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk3', 'Helper.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk3', 'Helper.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => {
			'Gtk3'                        => 0,
		},
		PREREQ_FATAL  => 1,

		META_MERGE => {
			resources => {
				homepage    => 'https://github.com/potyl/perl-Gtk3-Helper',
				bucktracker => 'https://github.com/potyl/perl-Gtk3-Helper/issues',
				repository  => 'https://github.com/potyl/perl-Gtk3-Helper',
			},
		},
	);
	WriteMakefile(@args);


	return 0;
}


exit main() unless caller;


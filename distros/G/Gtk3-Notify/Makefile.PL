use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::Spec;
use Data::Dumper;


sub main {
	# Create the Makefile
	my @args = (
		AUTHOR        => 'Thierry Vignaud <tvignaud@cpan.org>',
		NAME          => 'Gtk3::Notify',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk3', 'Notify.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk3', 'Notify.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => {
			'Glib::Object::Introspection' => 0,
			'Gtk3'                        => 0,
		},
		PREREQ_FATAL  => 1,

		META_MERGE => {
			resources => {
				homepage    => 'https://github.com/potyl/perl-Gtk3-Notify',
				bucktracker => 'https://github.com/potyl/perl-Gtk3-Notify/issues',
				repository  => 'https://github.com/potyl/perl-Gtk3-Notify',
			},
		},
	);
	WriteMakefile(@args);


	return 0;
}


exit main() unless caller;

